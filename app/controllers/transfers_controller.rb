class TransfersController < ApplicationController
  before_action :set_transfer, only: [ :show, :edit, :update, :destroy ]
  before_action :set_sale, only: [ :index, :new, :create ]
  before_action :set_suppliers, only: [ :new, :create, :edit, :update ]

  def index
    scope = if @sale
      @sale.transfers
    else
      Transfer.includes(:sale, :customer, :supplier)
    end
    @pagy, @transfers = pagy(scope.order(occurred_at: :desc))
  end

  def show
    @sale = @transfer.sale
  end

  def new
    return redirect_to(transfers_path, alert: "Selecciona una venta para crear un transfer.") unless @sale

    @transfer = @sale.transfers.build(customer: @sale.customer, supplier: @sale.supplier)
  end

  def edit
    @sale = @transfer.sale
  end

  def create
    return redirect_to(transfers_path, alert: "Selecciona una venta para crear un transfer.") unless @sale

    @transfer = @sale.transfers.build(transfer_params)
    @transfer.customer = @sale.customer
    if @transfer.save
      redirect_to sale_transfers_path(@sale), notice: "Transfer was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @sale = @transfer.sale
    if @transfer.update(transfer_params)
      redirect_to transfer_path(@transfer), notice: "Transfer was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    sale = @transfer.sale
    if @transfer.destroy
      redirect_to(sale ? sale_transfers_path(sale) : transfers_path, notice: "Transfer was successfully destroyed.")
    else
      redirect_to(sale ? sale_transfers_path(sale) : transfers_path, alert: @transfer.errors.full_messages.to_sentence)
    end
  end

  private

  def set_sale
    @sale = Sale.find_by(id: params[:sale_id])
  end

  def set_transfer
    @transfer = Transfer.find(params[:id])
  end

  def set_suppliers
    current_sale = @sale || @transfer&.sale
    supplier = current_sale&.supplier || @transfer&.supplier
    @suppliers = supplier ? [ supplier ] : Supplier.order(:name)
  end

  def transfer_params
    params.require(:transfer).permit(:code, :occurred_at, :supplier_id, :amount, :note)
  end
end
