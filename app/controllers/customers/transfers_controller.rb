module Customers
  class TransfersController < ApplicationController
    include TransferParamHelpers
    before_action :set_customer
    before_action :set_sales
    before_action :set_sale
    before_action :set_entities
    before_action :set_available_balances

    def new
      @transfer = build_transfer_for_customer
      @destination_entries = prefill_destination_entries(@transfer)
    end

    def create
      base_attrs = transfer_params.except(:from_entity_ref, :to_entity_ref, :destination_entries, :amount)
      @destination_entries = destination_entries_from_params(transfer_params)
      from_ref = transfer_params[:from_entity_ref].presence || "Customer:#{@customer.id}"
      builder = -> { build_transfer_for_customer(base_attrs, from_ref) }

      created, error_transfer = persist_destination_batch(
        base_attrs: base_attrs,
        destination_entries: @destination_entries,
        from_ref: from_ref,
        sale: @sale,
        builder: builder
      )

      if error_transfer
        @transfer = error_transfer
        render :new, status: :unprocessable_entity
      else
        @transfer = created.first
        notice = created.size > 1 ? "Transfers registrados correctamente." : "Transfer registrado correctamente."
        redirect_to customer_path(@customer), notice: notice
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
      @supplier_balances = supplier_balances_for(@suppliers)
      @user_balances = User.balances_by_user(@users.map(&:id))
    end

    def set_available_balances
      @customer_available_balance = @customer.available_transfer_total
      @sale_available_balance = @sale&.available_transfer_amount(excluding: @transfer)
    end

    def transfer_params
      params.require(:transfer).permit(
        :sale_id,
        :supplier_id,
        :amount,
        :from_other_name,
        :note,
        :payment_method,
        :from_entity_ref,
        :to_entity_ref,
        destination_entries: [ :to_entity_ref, :amount ]
      )
    end

    def build_transfer_for_customer(attributes = {}, from_ref = nil)
      from_ref ||= "Customer:#{@customer.id}"
      transfer = Transfer.new(attributes)
      assign_entities_from_refs(transfer, from_ref: from_ref, to_ref: nil)
      transfer.from_entity ||= @customer
      transfer.customer = @customer
      transfer.sale = @sale if @sale
      transfer.supplier ||= @sale&.supplier
      transfer.to_entity ||= @sale&.supplier
      transfer
    end

    def supplier_balances_for(suppliers)
      suppliers.each_with_object({}) do |supplier, balances|
        balances[supplier.id] = supplier.available_transfer_total
      end
    end
  end
end
