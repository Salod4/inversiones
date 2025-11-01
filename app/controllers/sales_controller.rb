class SalesController < ApplicationController
  before_action :set_sale, only: [ :show, :edit, :update, :destroy ]
  before_action :set_collections, only: [ :new, :create, :edit, :update ]

  def index
    @sales = Sale.includes(:customer, :supplier).order(date: :desc)
  end

  def show
    @sales_users = @sale.sales_users.includes(:user)
    @transfers = @sale.transfers.order(occurred_at: :desc)
  end

  def new
    @sale = Sale.new
  end

  def edit; end

  def create
    @sale = Sale.new(sale_params)
    if @sale.save
      redirect_to @sale, notice: "Sale was successfully created."
    else
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

  def sale_params
    params.require(:sale).permit(
      :code,
      :date,
      :customer_id,
      :supplier_id,
      :closing_id,
      :gross_deposit,
      :net_base,
      :provider_pct,
      :customer_fee_pct,
      :provider_commission,
      :customer_fee,
      :total_transfer_applied,
      :working_capital,
      :customer_balance,
      :status
    )
  end
end
