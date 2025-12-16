class ClosingsController < ApplicationController
  before_action :set_closing, only: [ :show, :edit, :update, :destroy, :customer_group_pdf ]

  def index
    @pagy, @closings = pagy(Closing.order(business_date: :desc))
  end

  def show
    @closing = Closing.find(params[:id])

    @sales = @closing
      .sales
      .includes(:customer, :supplier)
      .order(:code)

    @customer_closings = CustomerClosing.where(closing_id: @closing.id).includes(:customer).order("customers.name")
    @supplier_closings = SupplierClosing.where(closing_id: @closing.id).includes(:supplier).order("suppliers.name")
    @closing_transfers = Transfer.where(occurred_at: @closing.business_date.beginning_of_day..@closing.business_date.end_of_day).includes(:sale, :supplier, :customer)

    balances_by_customer = @customer_closings.each_with_object(Hash.new(0.to_d)) do |cc, memo|
      memo[cc.customer_id] += cc.customer_balance.to_d
    end

    all_group_defs = CustomerGroups.build(Customer.all).index_by { |g| g[:name] }
    group_defs = CustomerGroups.names.map do |name|
      all_group_defs[name] || { name:, customers: [], count: 0 }
    end

    group_openings = OpeningBalance.customer_groups.group(Arel.sql("LOWER(group_name)")).sum(:amount)

    @customer_group_totals = group_defs.map do |g|
      ids = g[:customers].map(&:id)
      opening = group_openings.fetch(g[:name].downcase, 0).to_d
      {
        name: g[:name],
        balance: ids.sum { |cid| balances_by_customer[cid] } + opening
      }
    end

    grouped_ids = group_defs.flat_map { |g| g[:customers].map(&:id) }
    @customer_ungrouped = balances_by_customer.reject { |cid, _| grouped_ids.include?(cid) }

    @customer_closing_by_customer_id = @customer_closings.index_by(&:customer_id)
    @customer_rows = @customer_closings.map do |cc|
      {
        customer_name: cc.customer&.name || "Cliente ##{cc.customer_id}",
        balance: cc.customer_balance,
        customer_closing: cc
      }
    end

    # Totales rápidos tomando los agregados históricos
    @sales_totals = {
      gross_deposit: @sales.sum(:gross_deposit),
      net_base: @sales.sum(:net_base),
      provider_commission: @sales.sum(:provider_commission),
      customer_fee: @sales.sum(:customer_fee),
      total_transfer_applied: @sales.sum(:total_transfer_applied),
      working_capital: @sales.sum(:working_capital),
      customer_balance: @customer_closings.sum(:customer_balance)
    }
  end

  def new
    @closing = Closing.new
  end

  def edit; end

  def create
    @closing = Closing.new(closing_params)
    if @closing.save
      redirect_to @closing, notice: "Closing was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @closing.update(closing_params)
      redirect_to @closing, notice: "Closing was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @closing.destroy
      redirect_to closings_url, notice: "Closing was successfully destroyed."
    else
      redirect_to closings_url, alert: @closing.errors.full_messages.to_sentence
    end
  end

  def customer_group_pdf
    group_name = params[:group_name]
    pdf_data = CustomerGroups::PdfReport.new(closing: @closing, group_name: group_name).render
    filename = "customer_group_#{@closing.id}_#{group_name.to_s.parameterize}.pdf"

    send_data pdf_data,
              filename: filename,
              type: "application/pdf",
              disposition: "attachment"
  rescue CustomerGroups::PdfReport::GroupNotFound
    redirect_to closing_path(@closing), alert: "Grupo #{group_name} no encontrado para este cierre."
  end

  private

  def set_closing
    @closing = Closing.find(params[:id])
  end

  def closing_params
    params.require(:closing).permit(
      :business_date,
      :closed_at,
      :status,
      :total_customers,
      :total_suppliers,
      :difference
    )
  end
end
