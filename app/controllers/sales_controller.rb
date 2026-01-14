class SalesController < ApplicationController
  before_action :set_sale, only: [ :show, :edit, :update, :destroy ]
  before_action :set_collections, only: [ :new, :create, :edit, :update ]
  before_action :prepare_sales_users_for_form, only: [ :new, :edit ]

  def index
    @today = Date.current
    @tomorrow = @today + 1.day

    @pagy, @sales = pagy(Sale.includes(:customer, :supplier, :closing).order(date: :desc))

    @closing_today_exists = closing_exists_for?(@today)
    @closing_tomorrow_exists = closing_exists_for?(@tomorrow)
    @next_closable_date = next_closable_date
  end

  def show
    @sales_users = @sale.sales_users.includes(:user)
    @transfers = @sale.transfers.order(occurred_at: :desc)
    prepare_transfer_form_support
  end

  def new
    @sale = Sale.new
    @sale.customer_id = params[:customer_id] if params[:customer_id].present?
    @sale.supplier_id = params[:supplier_id] if params[:supplier_id].present?
    @sale.date ||= Closing.open_business_date(Date.current)


    if @sale.customer_id.present? && @sale.supplier_id.present?
      Sales::Prefill.call(@sale)
    else
      @sale.sales_users.build
    end
  end

  def prefill
    sale = Sale.new(customer_id: params[:customer_id], supplier_id: params[:supplier_id])
    Sales::Prefill.call(sale)
    supplier_code = lookup_supplier_code(sale)
    customer_name = lookup_customer_name(sale)
    render json: {
      provider_pct: sale.provider_pct,
      customer_fee_pct: sale.customer_fee_pct,
      sales_users: sale.sales_users.map do |su|
        {
          user_id: su.user_id,
          user_name: prefill_user_name(su, supplier_code, customer_name),
          commission_pct: su.commission_pct
        }
      end
    }
  end

  def edit; end

  def create
    @sale = Sale.new(sale_params)
    Sales::SnapshotPcts.call(@sale)

    if @sale.save
      redirect_to @sale, notice: "Venta creada."
    else
      prepare_sales_users_for_form
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @sale.update(sale_params)
      redirect_to @sale, notice: "Sale was successfully updated."
    else
      prepare_sales_users_for_form
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @sale.destroy
      redirect_to sales_url, notice: "Sale was successfully destroyed."
    else
      redirect_to sales_url, alert: @sale.errors.full_messages.to_sentence
    end
  end

  def attach_file
    @sale = Sale.find(params[:id])
    if params[:attachments].present?
      @sale.attachments.attach(params[:attachments])
      redirect_to @sale, notice: "Archivo adjuntado."
    else
      redirect_to @sale, alert: "No se seleccionó archivo."
    end
  end

  def delete_attachment
    @sale = Sale.find(params[:id])
    attachment = @sale.attachments.find_by(id: params[:attachment_id])
    if attachment
      attachment.purge
      redirect_to @sale, notice: "Adjunto eliminado."
    else
      redirect_to @sale, alert: "Adjunto no encontrado."
    end
  end

  def attach_file
    @sale = Sale.find(params[:id])
    if params[:attachments].present?
      @sale.attachments.attach(params[:attachments])
      redirect_to @sale, notice: "Archivo adjuntado."
    else
      redirect_to @sale, alert: "No se seleccionó archivo."
    end
  end
  def close_today
    business_date = parsed_business_date

    unless allowed_closing_date?(business_date)
      redirect_to sales_path, alert: "Solo puedes cerrar ventas de fechas desde hoy en adelante."
      return
    end

    Closings::CloseDay.new(business_date: business_date).call
    redirect_to sales_path, notice: "Cierre de #{formatted_date(business_date)} realizado correctamente."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to sales_path, alert: "No se pudo cerrar: #{e.message}"
  rescue ArgumentError, Date::Error
    redirect_to sales_path, alert: "Fecha de cierre inválida."
  end

  private

  def closing_exists_for?(date)
    Closing.closed_for?(date)
  end

  def next_closable_date
    date = Date.current
    90.times do
      return date unless closing_exists_for?(date)
      date += 1.day
    end
    nil
  end

  def parsed_business_date
    raw_date = params[:business_date].presence
    return Date.current if raw_date.blank?

    Date.parse(raw_date.to_s)
  end

  def allowed_closing_date?(date)
    date.present? && date >= Date.current
  end

  def formatted_date(date)
    date.strftime("%d/%m/%Y")
  end

  def set_sale
    @sale = Sale.find(params[:id])
  end

  def prepare_transfer_form_support
    @transfer = @sale.transfers.build

    @suppliers = [ @sale.supplier ].compact
    @customers = Customer.order(:name)
    @customer_groups = CustomerGroups.build(@customers)
    grouped_ids = @customer_groups.flat_map { |g| g[:customers].map(&:id) }
    @ungrouped_customers = @customers.reject { |c| grouped_ids.include?(c.id) }
    @users = User.order(:name)
    @supplier_balances = supplier_balances_for(@suppliers)
    @user_balances = {}
    @destination_entries = []
  end

  def supplier_balances_for(suppliers)
    ids = suppliers.map(&:id)
    return {} if ids.empty?
    sales_sum = Sale.where(supplier_id: ids).group(:supplier_id).sum(Arel.sql("COALESCE(gross_deposit,0) - COALESCE(provider_commission,0)"))
    transfer_sum = Transfer.outgoing_sum_by_supplier(ids)
    ids.index_with do |sid|
      gross = BigDecimal(sales_sum[sid] || 0)
      transferred = BigDecimal(transfer_sum[sid] || 0)
      gross - transferred
    end
  end

  def set_collections
    @customers = Customer.order(:name)
    @suppliers = Supplier.order(:name)
    @closings = Closing.order(business_date: :desc)
  end

  def sale_params
    params.require(:sale).permit(
      :code,
      :date,
      :customer_id,
      :supplier_id,
      :closing_id,
      :gross_deposit,
      :net_base,
      :provider_pct_override,
      :customer_fee_pct_override,
      attachments: [],
      sales_users_attributes: [
        :id,
        :user_id,
        :commission_pct_override,
        :_destroy
      ]
    )
  end

  def lookup_supplier_code(sale)
    sale.supplier&.code || Supplier.where(id: sale.supplier_id).pick(:code)
  end

  def lookup_customer_name(sale)
    sale.customer&.name || Customer.where(id: sale.customer_id).pick(:name)
  end

  def prefill_user_name(sales_user, supplier_code, customer_name)
    if sales_user.user&.code == "SUBAG"
      Sales::Subagents.display_name_for(supplier_code, customer_name, sales_user.commission_pct) ||
        sales_user.user&.name ||
        "Subagente"
    else
      sales_user.user&.name || sales_user.user&.email || "Vendedor"
    end
  end

  def prepare_sales_users_for_form
    return unless defined?(@sale) && @sale
    @sales_users_for_form = @sale.sales_users.order(:id).to_a.uniq { |su| su.user_id }.first(Sale::MAX_SELLERS)
  end
end
