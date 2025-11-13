class CustomerClosingsController < ApplicationController
  before_action :set_closing
  before_action :set_customer_closing, only: [ :show, :edit, :update, :destroy ]
  before_action :set_customers, only: [ :new, :create, :edit, :update ]

  def index
    @pagy, @customer_closings = pagy(@closing.customer_closings.includes(:customer))
  end

  def show; end

  def new
    @customer_closing = @closing.customer_closings.build
  end

  def edit; end

  def create
    @customer_closing = @closing.customer_closings.build(customer_closing_params)
    if @customer_closing.save
      redirect_to closing_path(@closing), notice: "Customer closing was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @customer_closing.update(customer_closing_params)
      redirect_to closing_path(@closing), notice: "Customer closing was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @customer_closing.destroy
      redirect_to closing_path(@closing), notice: "Customer closing was successfully destroyed."
    else
      redirect_to closing_path(@closing), alert: @customer_closing.errors.full_messages.to_sentence
    end
  end

  private

  def set_closing
    @closing = Closing.find(params[:closing_id])
  end

  def set_customer_closing
    @customer_closing = @closing.customer_closings.find(params[:id])
  end

  def set_customers
    @customers = Customer.order(:name)
  end

  def customer_closing_params
    params.require(:customer_closing).permit(:customer_id, :customer_balance, :receivables)
  end
end
