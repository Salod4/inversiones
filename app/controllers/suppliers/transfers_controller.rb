module Suppliers
  class TransfersController < ApplicationController
    include TransferParamHelpers
    before_action :set_supplier
    before_action :set_sales
    before_action :ensure_sales_present
    before_action :set_sale
    before_action :set_entities

    def new
      @transfer = build_transfer_for_sale
      @destination_entries = prefill_destination_entries(@transfer)
    end

    def create
      base_attrs = transfer_params.except(:from_entity_ref, :to_entity_ref, :destination_entries, :amount)
      @destination_entries = destination_entries_from_params(transfer_params)
      from_ref = transfer_params[:from_entity_ref].presence || "Supplier:#{@supplier.id}"
      builder = -> { build_transfer_for_sale(base_attrs, from_ref) }

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
        redirect_to supplier_path(@supplier), notice: notice
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
      @supplier_balances = supplier_balances_for(@suppliers)
      @user_balances = {}
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

    def build_transfer_for_sale(attributes = {}, from_ref = nil)
      from_ref ||= "Supplier:#{@supplier.id}"
      transfer = @sale.transfers.build(attributes)
      assign_entities_from_refs(transfer, from_ref: from_ref, to_ref: nil)
      transfer.from_entity ||= @supplier
      transfer.to_entity ||= @sale.customer
      transfer.customer = @sale.customer
      transfer.supplier ||= @supplier
      transfer
    end

    def supplier_balances_for(suppliers)
      ids = suppliers.map(&:id)
      return {} if ids.empty?
      sales_sum = Sale.where(supplier_id: ids).group(:supplier_id).sum(Arel.sql("COALESCE(gross_deposit,0) - COALESCE(provider_commission,0)"))
      transfer_sum = Transfer.outgoing_sum_by_supplier(ids)
      ids.index_with do |sid|
        gross = BigDecimal(sales_sum[sid] || 0)
        transferred = BigDecimal(transfer_sum[sid] || 0)
        gross - transferred
      end
    end
  end
end
