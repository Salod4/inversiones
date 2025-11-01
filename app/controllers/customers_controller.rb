class CustomersController < ApplicationController
  before_action :set_customer, only: [ :show, :edit, :update, :destroy ]

  def index
    @customers = Customer.order(:name)
  end

  def show; end

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
