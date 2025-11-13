module Customers
  class TransfersController < ApplicationController
    before_action :set_customer
    before_action :set_sales
    before_action :ensure_sales_present
    before_action :set_sale
    before_action :set_suppliers

    def new
      @transfer = build_transfer_for_sale
    end

    def create
      @transfer = build_transfer_for_sale(transfer_params)

      if @transfer.save
        redirect_to customer_path(@customer), notice: "Transfer registrado correctamente."
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def set_customer
      @customer = Customer.find(params[:customer_id])
    end

    def set_sales
      @sales = @customer.sales.includes(:supplier).order(date: :desc)
    end

    def ensure_sales_present
      return if @sales.any?

      redirect_to customer_path(@customer), alert: "Este cliente no tiene ventas para asociar transfers."
      nil
    end

    def set_sale
      sale_id = params[:sale_id] || params.dig(:transfer, :sale_id)
      @sale = @sales.find_by(id: sale_id) || @sales.first
    end

    def set_suppliers
      @suppliers = [ @sale&.supplier ].compact
    end

    def transfer_params
      params.require(:transfer).permit(:sale_id, :supplier_id, :amount, :note)
    end

    def build_transfer_for_sale(attributes = {})
      transfer = @sale.transfers.build(attributes)
      transfer.supplier ||= @sale.supplier
      transfer
    end
  end
end
