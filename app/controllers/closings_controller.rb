class ClosingsController < ApplicationController
  before_action :set_closing, only: [ :show, :edit, :update, :destroy ]

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

    # Totales rápidos para el footer de la tabla de ventas
    @sales_totals = {
      gross_deposit: @sales.sum(:gross_deposit),
      net_base: @sales.sum(:net_base),
      provider_commission: @sales.sum(:provider_commission),
      customer_fee: @sales.sum(:customer_fee),
      total_transfer_applied: @sales.sum(:total_transfer_applied),
      working_capital: @sales.sum(:working_capital),
      customer_balance: @sales.sum(:customer_balance)
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
