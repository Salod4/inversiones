class CustomersController < ApplicationController
  before_action :set_customer, only: [ :show, :edit, :update, :destroy ]

  def index
    @q = Customer
          .left_joins(:suppliers)         # permite filtrar/ordenar por proveedor
          .distinct
          .ransack(params[:q])

    customers_scope = @q.result.includes(:suppliers).order("customers.name ASC")
    @pagy, @customers = pagy(customers_scope)

    # Para el <select> de filtros
    @suppliers = Supplier.order(:name).pluck(:name, :id)
  end

  def show
    @suppliers = @customer.suppliers.order(:name)

    # Ventas recientes del cliente (ligero y sin cálculos de negocio)
    @sales = @customer.sales
                      .includes(:supplier)
                      .order(date: :desc)
                      .limit(25)

    @customer_total_deposit = @customer.sales.sum(:gross_deposit) || 0
    @customer_total_transferred = Transfer
                                    .joins(:sale)
                                    .where(sales: { customer_id: @customer.id })
                                    .sum(:amount) || 0
    @customer_available_balance = @customer_total_deposit - @customer_total_transferred

    @customer_transfers = Transfer
                            .joins(:sale)
                            .includes(:supplier, :sale)
                            .where(sales: { customer_id: @customer.id })
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
