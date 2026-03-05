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
      balance = customer_group_total_cliente_balance(group[:name], group[:customers].map(&:id))
      group.merge(balance: balance)
    end
    grouped_ids = @customer_groups.flat_map { |g| g[:customers].map(&:id) }
    @ungrouped_customers = @customers.reject { |c| grouped_ids.include?(c.id) }
    @users = User.order(:name)
    @supplier_balances = supplier_balances_for(@suppliers)
    @user_balances = User.balances_by_user(@users.map(&:id))
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
    suppliers.each_with_object({}) do |supplier, balances|
      balances[supplier.id] = supplier.available_transfer_total
    end
  end

  def transfers_scope_for_balance
    scope = Transfer.all
    return scope unless @transfer&.persisted?

    scope.where.not(id: @transfer.id)
  end

  # Mantiene el mismo criterio de "TOTAL CLIENTE" usado en CustomersController#group.
  def customer_group_total_cliente_balance(group_name, customer_ids)
    return 0.to_d if customer_ids.blank?

    transfers_scope = transfers_scope_for_balance
    base_sales_scope = Sale.where(customer_id: customer_ids)
    sales_scope = base_sales_scope.includes(:sales_users)

    group_total_after_pcts = sales_scope.sum { |sale| sale.net_after_provider_and_sellers.to_d }
    group_opening_balance = OpeningBalance.total_for_group(group_name)
    group_total_transferred = transfers_scope.where(
      sale_id: base_sales_scope.select(:id),
      to_entity_type: "Supplier"
    ).sum(:amount).to_d

    direct_outgoing_total = 0.to_d
    transfers_scope.where(
      sale_id: nil,
      from_entity_type: "Customer",
      from_entity_id: customer_ids
    ).find_each do |transfer|
      direct_outgoing_total += transfer.total_outgoing
    end

    direct_from_customers_total = transfers_scope.where(
      sale_id: nil,
      to_entity_type: "Customer",
      to_entity_id: customer_ids,
      from_entity_type: "Customer"
    ).sum(:amount).to_d

    direct_to_customers = transfers_scope.where(
      sale_id: nil,
      to_entity_type: "Customer",
      to_entity_id: customer_ids
    ).where.not(from_entity_type: "Customer").sum(:amount).to_d

    direct_to_group = transfers_scope.where(
      sale_id: nil,
      to_entity_type: "CustomerGroup"
    ).where("lower(to_group) = ?", group_name.to_s.downcase).sum(:amount).to_d

    sale_transfers_to_customers = transfers_scope.where(
      sale_id: base_sales_scope.select(:id),
      to_entity_type: "Customer",
      to_entity_id: customer_ids
    ).sum(:amount).to_d

    sale_transfers_to_group = transfers_scope.where(
      sale_id: base_sales_scope.select(:id),
      to_entity_type: "CustomerGroup"
    ).where("lower(to_group) = ?", group_name.to_s.downcase).sum(:amount).to_d

    group_total_received = direct_to_customers + direct_to_group + sale_transfers_to_customers + sale_transfers_to_group

    group_total_after_pcts + group_opening_balance - group_total_transferred -
      group_total_received - direct_outgoing_total + direct_from_customers_total
  end
end
