class SalesController < ApplicationController
  before_action :set_sale, only: [ :show, :edit, :update, :destroy ]
  before_action :set_collections, only: [ :new, :create, :edit, :update ]

  def index
    @pagy, @sales = pagy(Sale.includes(:customer, :supplier).order(date: :desc))
    @closing_today_exists = Closing.closed_for?(Date.current)
  end

  def show
    @sales_users = @sale.sales_users.includes(:user)
    @transfers = @sale.transfers.order(occurred_at: :desc)
  end

  def new
    @sale = Sale.new
    @sale.customer_id = params[:customer_id] if params[:customer_id].present?
    @sale.supplier_id = params[:supplier_id] if params[:supplier_id].present?



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
      Sales::Prefill.call(@sale) if @sale.customer_id.present? && @sale.supplier_id.present?
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @sale.update(sale_params)
      redirect_to @sale, notice: "Sale was successfully updated."
    else
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
   def close_today
    Closings::CloseDay.new(business_date: Date.current).call
    redirect_to sales_path, notice: "Cierre de hoy realizado correctamente."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to sales_path, alert: "No se pudo cerrar: #{e.message}"
  end

  private

  def set_sale
    @sale = Sale.find(params[:id])
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
      :status,
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
end
