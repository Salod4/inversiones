module Suppliers
  class TransfersController < ApplicationController
    before_action :set_supplier
    before_action :set_sales
    before_action :ensure_sales_present
    before_action :set_sale
    before_action :set_entities

    def new
      @transfer = build_transfer_for_sale
    end

    def create
      @transfer = build_transfer_for_sale(transfer_params)

      if @transfer.save
        redirect_to supplier_path(@supplier), notice: "Transfer registrado correctamente."
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def set_supplier
      @supplier = Supplier.find(params[:supplier_id])
    end

    def set_sales
      @sales = @supplier.sales.includes(:customer).order(date: :desc)
    end

    def ensure_sales_present
      return if @sales.any?

      redirect_to supplier_path(@supplier), alert: "Este proveedor no tiene ventas para asociar transfers."
      nil
    end

    def set_sale
      sale_id = params[:sale_id] || params.dig(:transfer, :sale_id)
      @sale = @sales.find_by(id: sale_id) || @sales.first
    end

    def set_entities
      @suppliers = [ @supplier ]
      @customers = Customer.order(:name)
      @users = User.order(:name)
    end

    def transfer_params
      params.require(:transfer).permit(:sale_id, :supplier_id, :amount, :note)
    end

    def build_transfer_for_sale(attributes = {})
      transfer = @sale.transfers.build(attributes.merge(from_entity: @supplier, to_entity: @sale.customer))
      transfer.customer = @sale.customer
      transfer.supplier ||= @supplier
      transfer
    end
  end
end
