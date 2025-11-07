class SalesController < ApplicationController
  before_action :set_sale, only: [ :show, :edit, :update, :destroy ]
  before_action :set_collections, only: [ :new, :create, :edit, :update ]

  def index
    @sales = Sale.includes(:customer, :supplier).order(date: :desc)
  end

  def show
    hydrate_sale_totals(@sale)
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
    render json: {
      provider_pct: sale.provider_pct,
      customer_fee_pct: sale.customer_fee_pct,
      sales_users: sale.sales_users.map do |su|
        { user_id: su.user_id, commission_pct: su.commission_pct }
      end
    }
  end

  def edit; end

  def create
    @sale = Sale.new(sale_params)
    Sales::SnapshotPcts.call(@sale)

    if @sale.save
      redirect_to @sale, notice: "Venta creada."
    @sale.net_base = @sale.gross_deposit * 0.84
    @sale.provider_commission = @sale.gross_deposit * @sale.provider_pct / 100.0
    @sale.customer_fee = @sale.gross_deposit * @sale.customer_fee_pct / 100
    else
      if @sale.customer_id.present? && @sale.supplier_id.present?
        Sales::Prefill.call(@sale)
            @sale.net_base = @sale.gross_deposit * 0.84
    @sale.provider_commission = @sale.gross_deposit * @sale.provider_pct / 100.0
    @sale.customer_fee = @sale.gross_deposit * @sale.customer_fee_pct / 100
      end
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

  private

  def set_sale
    @sale = Sale.find(params[:id])
  end

  def set_collections
    @customers = Customer.order(:name)
    @suppliers = Supplier.order(:name)
    @closings = Closing.order(business_date: :desc)
  end

  def hydrate_sale_totals(sale)
    deposit = sale.gross_deposit.to_f
    sale.net_base = (deposit * 0.84).round(2)
    sale.provider_commission = (deposit * sale.provider_pct.to_f / 100.0).round(2)
    sale.customer_fee = (deposit * sale.customer_fee_pct.to_f / 100.0).round(2)
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
end
