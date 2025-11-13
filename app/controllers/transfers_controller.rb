class TransfersController < ApplicationController
  before_action :set_sale, only: [ :index, :new, :create ]
  before_action :set_transfer, only: [ :show, :edit, :update, :destroy ]
  before_action :set_suppliers, only: [ :new, :create, :edit, :update ]

  def index
    @pagy, @transfers = pagy(@sale.transfers.order(occurred_at: :desc))
  end

  def show
    @sale = @transfer.sale
  end

  def new
    @transfer = @sale.transfers.build(supplier: @sale.supplier)
  end

  def edit
    @sale = @transfer.sale
  end

  def create
    @transfer = @sale.transfers.build(transfer_params)
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
      redirect_to sale_transfers_path(sale), notice: "Transfer was successfully destroyed."
    else
      redirect_to sale_transfers_path(sale), alert: @transfer.errors.full_messages.to_sentence
    end
  end

  private

  def set_sale
    @sale = Sale.find(params[:sale_id])
  end

  def set_transfer
    @transfer = Transfer.find(params[:id])
  end

  def set_suppliers
    current_sale = @sale || @transfer&.sale
    supplier = current_sale&.supplier
    @suppliers = supplier ? [ supplier ] : Supplier.order(:name)
  end

  def transfer_params
    params.require(:transfer).permit(:code, :occurred_at, :supplier_id, :amount, :note)
  end
end
