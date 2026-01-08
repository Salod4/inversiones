class TransfersController < ApplicationController
  include TransferParamHelpers
  before_action :set_transfer, only: [ :show, :edit, :update, :destroy ]
  before_action :set_sale, only: [ :index, :new, :create ]
  before_action :set_entities, only: [ :new, :create, :edit, :update ]

  def index
    scope = if @sale
      @sale.transfers
    else
      Transfer.includes(:sale, :customer, :supplier)
    end
    ordered_scope = scope.order(occurred_at: :desc)
    @pagy, @transfers = pagy(ordered_scope)

    totals_scope = @sale ? @sale.transfers : Transfer.all
    stats = {
      count: totals_scope.count,
      total_outgoing: 0.to_d,
      deposit_count: 0,
      efectivo_count: 0,
      deposit_amount: 0.to_d,
      efectivo_amount: 0.to_d
    }
    totals_scope.find_each do |t|
      outgoing = t.total_outgoing
      stats[:total_outgoing] += outgoing
      case t.payment_method
      when "deposito"
        stats[:deposit_count] += 1
        stats[:deposit_amount] += outgoing
      when "efectivo"
        stats[:efectivo_count] += 1
        stats[:efectivo_amount] += outgoing
      end
    end
    @transfer_stats = stats
  end

  def show
    @sale = @transfer.sale
  end

  def new
    if @sale
      @transfer = @sale.transfers.build(customer: @sale.customer, supplier: @sale.supplier)
      @transfer.from_entity = @sale.customer
      @transfer.to_entity = @sale.supplier
    else
      @transfer = Transfer.new
    end
    @destination_entries = prefill_destination_entries(@transfer)
  end

  def edit
    @sale = @transfer.sale
    @destination_entries = prefill_destination_entries(@transfer)
  end

  def create
    base_attrs = transfer_params.except(:from_entity_ref, :to_entity_ref, :destination_entries, :amount)
    @destination_entries = destination_entries_from_params(transfer_params)
    to_cash_box = ActiveModel::Type::Boolean.new.cast(transfer_params[:to_cash_box])
    if to_cash_box && @destination_entries.any?
      total_dest = @destination_entries.sum { |d| d[:amount].to_d }
      @destination_entries = [ { to_entity_ref: "CashBox:internal", amount: total_dest } ]
      base_attrs[:cash_box_amount] = total_dest
    else
      base_attrs[:cash_box_amount] = transfer_params[:cash_box_amount] || 0
    end
    from_ref = transfer_params[:from_entity_ref].presence
    from_ref ||= "Customer:#{@sale.customer_id}" if @sale&.customer_id
    builder = -> { build_transfer_with_base(base_attrs, from_ref) }
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
      notice = created.size > 1 ? "Transfers creados correctamente." : "Transfer was successfully created."
      redirect_to(@sale ? sale_transfers_path(@sale) : transfers_path, notice: notice)
    end
  end

  def update
    @sale = @transfer.sale
    base_attrs = transfer_params.except(:from_entity_ref, :to_entity_ref, :destination_entries, :amount)
    @destination_entries = destination_entries_from_params(transfer_params)
    to_cash_box = ActiveModel::Type::Boolean.new.cast(transfer_params[:to_cash_box])
    if to_cash_box && @destination_entries.any?
      total_dest = @destination_entries.sum { |d| d[:amount].to_d }
      @destination_entries = [ { to_entity_ref: "CashBox:internal", amount: total_dest } ]
      base_attrs[:cash_box_amount] = total_dest
    else
      base_attrs[:cash_box_amount] = transfer_params[:cash_box_amount] || @transfer.cash_box_amount
    end
    from_ref = transfer_params[:from_entity_ref].presence || entity_ref_for(@transfer, :from)
    to_ref = @destination_entries.first&.dig(:to_entity_ref).presence || transfer_params[:to_entity_ref].presence || entity_ref_for(@transfer, :to)
    amount_value = @destination_entries.first&.dig(:amount) || transfer_params[:amount] || @transfer.amount

    assign_entities_from_refs(@transfer, from_ref: from_ref, to_ref: to_ref)

    if @transfer.update(base_attrs.merge(amount: amount_value))
      redirect_to transfer_path(@transfer), notice: "Transfer was successfully updated."
    else
      @destination_entries = @destination_entries.presence || prefill_destination_entries(@transfer)
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

  def set_entities
    current_sale = @sale || @transfer&.sale
    supplier = current_sale&.supplier || @transfer&.supplier
    @suppliers = supplier ? [ supplier ] : Supplier.order(:name)
    @customers = Customer.order(:name)
    @customer_groups = CustomerGroups.build(@customers).map do |group|
      balance = group[:customers].sum { |c| c.available_transfer_total(excluding: @transfer) }
      group.merge(balance: balance)
    end
    grouped_ids = @customer_groups.flat_map { |g| g[:customers].map(&:id) }
    @ungrouped_customers = @customers.reject { |c| grouped_ids.include?(c.id) }
    @users = User.order(:name)
    @supplier_balances = supplier_balances_for(@suppliers)
    @user_balances = {}
    @cash_box_balance = Transfer.cash_box_balance
  end

  def transfer_params
    params.require(:transfer).permit(
      :code,
      :occurred_at,
      :supplier_id,
      :amount,
      :cash_box_amount,
      :from_other_name,
      :note,
      :payment_method,
      :from_entity_ref,
      :to_entity_ref,
      :to_cash_box,
      destination_entries: [ :to_entity_ref, :amount ]
    )
  end

  def build_transfer_with_base(base_attrs, from_ref)
    transfer = (@sale ? @sale.transfers.build : Transfer.new)
    transfer.assign_attributes(base_attrs)
    assign_entities_from_refs(transfer, from_ref: from_ref, to_ref: nil)
    if @sale
      transfer.customer ||= @sale.customer
      transfer.supplier ||= @sale.supplier
    end
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
