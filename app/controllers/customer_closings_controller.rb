class CustomerClosingsController < ApplicationController
  before_action :set_closing
  before_action :set_customer_closing, only: [ :show, :edit, :update ]

  def index
    @customer_closings = @closing.customer_closings.includes(:customer)
  end

  def show
    @sales  = @customer_closing.sales_for_closing
    @totals = @customer_closing.totals
  end
   def group
    @group_name = params[:name]

    # Regla de negocio: grupos por prefijo (coincide con las seeds)
    @customers = Customer.where("name LIKE ?", "#{@group_name}%")

    @customer_closings = CustomerClosing
      .where(closing: @closing, customer: @customers)
      .includes(:customer)
      .order("customer_closings.customer_balance DESC")

    @group_total = @customer_closings.sum(:customer_balance)
  end

  def edit; end

  def update
    if @customer_closing.update(customer_closing_params)
      redirect_to closing_customer_closing_path(@closing, @customer_closing),
                  notice: "Cierre de cliente actualizado correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_closing
    @closing = Closing.find(params[:closing_id])
  end

  def set_customer_closing
    @customer_closing = @closing.customer_closings.find(params[:id])
  end

  def customer_closing_params
    params.require(:customer_closing).permit(:customer_balance, :receivables)
  end
end
