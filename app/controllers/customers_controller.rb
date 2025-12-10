class CustomersController < ApplicationController
  before_action :set_customer, only: [ :show, :edit, :update, :destroy ]

  def index
    @q = Customer
          .left_joins(:suppliers)         # permite filtrar/ordenar por proveedor
          .distinct
          .ransack(params[:q])

    filtered_scope = @q.result.includes(:suppliers).order("customers.name ASC")
    @grouped_customers = CustomerGroups.build(filtered_scope)
    grouped_ids = @grouped_customers.flat_map { |g| g[:customers].map(&:id) }

    customers_scope = filtered_scope.where.not(customers: { id: grouped_ids })
    @pagy, @customers = pagy(customers_scope)

    # Para el <select> de filtros
    @suppliers = Supplier.order(:name).pluck(:name, :id)
  end

  def group
    @group = CustomerGroups.find_by_name(params[:name], Customer.all)
    unless @group
      redirect_to customers_path, alert: "Grupo no encontrado" and return
    end

    customer_ids = @group[:customers].map(&:id)
    @group_search_query = params[:q].to_s.strip
    filtered_customer_ids =
      if @group_search_query.present?
        @group[:customers].select { |c| c.name.downcase.include?(@group_search_query.downcase) }.map(&:id)
      else
        customer_ids
      end
    @display_customers = @group[:customers].select { |c| filtered_customer_ids.include?(c.id) }

    base_sales_scope = Sale.where(customer_id: filtered_customer_ids)
    sales_scope = base_sales_scope.includes(:supplier, :customer, :sales_users, :transfers)

    @group_total_deposit = base_sales_scope.sum(:gross_deposit).to_d
    @group_total_after_pcts = sales_scope.sum { |s| s.net_after_provider_and_sellers.to_d }
    @group_total_transferred = sales_scope.sum { |s| s.total_transfer_applied.to_d }
    direct_received = Transfer.where(
      customer_id: filtered_customer_ids,
      sale_id: nil,
      to_entity_type: "Customer"
    ).group(:customer_id).sum(:amount)

    @group_total_direct_received = direct_received.values.sum.to_d
    @group_available_balance = @group_total_after_pcts - @group_total_transferred - @group_total_direct_received

    @per_customer_deposit = Hash.new(0)
    @per_customer_after_pcts = Hash.new(0)
    @per_customer_transfers = Hash.new(0)
    @per_customer_direct_received = Hash.new(0)
    @per_customer_balances = Hash.new(0)

    sales_scope.group_by(&:customer_id).each do |cid, sales|
      gross_total = sales.sum { |s| s.gross_deposit.to_d }
      net_total = sales.sum { |s| s.net_after_provider_and_sellers.to_d }
      transfers_total = sales.sum { |s| s.total_transfer_applied.to_d }
      @per_customer_deposit[cid] = gross_total
      @per_customer_after_pcts[cid] = net_total
      @per_customer_transfers[cid] = transfers_total
      direct = direct_received[cid].to_d
      @per_customer_direct_received[cid] = direct
      @per_customer_balances[cid] = net_total - transfers_total - direct
    end

    @sales = sales_scope.order(date: :desc).limit(50)
  end

  def show
    @suppliers = @customer.suppliers.order(:name)

    base_sales_scope = @customer.sales
    sales_scope = base_sales_scope.includes(:supplier, :sales_users, :transfers)
    @sales = sales_scope.order(date: :desc).limit(25)

    @customer_total_deposit = base_sales_scope.sum(:gross_deposit).to_d
    @customer_total_after_pcts = sales_scope.sum { |s| s.net_after_provider_and_sellers.to_d }
    @customer_total_transferred = sales_scope.sum { |s| s.total_transfer_applied.to_d }

    # Transfers recibidos directamente (sin venta) que reducen lo adeudado
    @customer_direct_received = Transfer.where(
      customer_id: @customer.id,
      sale_id: nil,
      to_entity_type: "Customer"
    ).sum(:amount).to_d

    @customer_available_balance = @customer_total_after_pcts - @customer_total_transferred - @customer_direct_received

    @customer_transfers = Transfer
                            .includes(:supplier, :sale)
                            .where(customer_id: @customer.id)
                            .order(occurred_at: :desc)
  end

  def new
    @customer = Customer.new
  end

  def edit; end

  def create
    @customer = Customer.new(customer_params)
    if @customer.save
      redirect_to @customer, notice: "Customer was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @customer.update(customer_params)
      redirect_to @customer, notice: "Customer was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @customer.destroy
      redirect_to customers_url, notice: "Customer was successfully destroyed."
    else
      redirect_to customers_url, alert: @customer.errors.full_messages.to_sentence
    end
  end

  private

  def set_customer
    @customer = Customer.find(params[:id])
  end

  def customer_params
    params.require(:customer).permit(:code, :name, :default_customer_fee_pct)
  end
end
