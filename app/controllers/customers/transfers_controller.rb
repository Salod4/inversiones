module Customers
  class TransfersController < ApplicationController
    before_action :set_customer
    before_action :set_sales
    before_action :set_sale
    before_action :set_entities
    before_action :set_available_balances

    def new
      @transfer = build_transfer_for_customer
    end

    def create
      @transfer = build_transfer_for_customer(transfer_params)

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

    def set_sale
      sale_id = params[:sale_id] || params.dig(:transfer, :sale_id)
      @sale = @sales.find_by(id: sale_id)
    end

    def set_entities
      @suppliers = if @sale
        [ @sale.supplier ].compact
      else
        Supplier.order(:name)
      end
      @customers = Customer.order(:name)
      @users = User.order(:name)
    end

    def set_available_balances
      base_sales_scope = @customer.sales
      sales_scope = base_sales_scope.includes(:supplier, :sales_users, :transfers)

      total_after_pcts = sales_scope.sum { |s| s.net_after_provider_and_sellers.to_d }
      total_transferred = sales_scope.sum { |s| s.total_transfer_applied.to_d }

      @customer_available_balance = total_after_pcts - total_transferred
      @sale_available_balance = @sale&.available_transfer_amount(excluding: @transfer)
    end

    def transfer_params
      params.require(:transfer).permit(:sale_id, :supplier_id, :amount, :note)
    end

    def build_transfer_for_customer(attributes = {})
      Transfer.new(attributes.merge(from_entity: @customer)).tap do |transfer|
        transfer.customer = @customer
        transfer.sale = @sale if @sale
        transfer.supplier ||= @sale&.supplier
        transfer.to_entity ||= @sale&.supplier
      end
    end
  end
end
