class CustomersController < ApplicationController
  before_action :set_customer, only: [ :show, :edit, :update, :destroy, :update_opening_balance ]
  before_action :load_form_collections, only: [ :new, :edit, :create, :update ]
  before_action :build_default_associations, only: [ :new, :edit ]

  def index
    @q = Customer
          .left_joins(:suppliers)         # permite filtrar/ordenar por proveedor
          .distinct
          .ransack(params[:q])
    @balance_filter = params[:balance].presence || "all"

    filtered_scope = @q.result.includes(:suppliers).order("customers.name ASC")
    @grouped_customers = CustomerGroups.build(filtered_scope)
    grouped_ids = @grouped_customers.flat_map { |g| g[:customers].map(&:id) }

    customers_scope = filtered_scope.where.not(customers: { id: grouped_ids })
    customers = customers_scope.to_a
    balances = customers.index_with { |customer| customer.available_transfer_total }
    customers = case @balance_filter
                when "positive"
                  customers.select { |customer| balances[customer].to_d.positive? }
                when "zero"
                  customers.select { |customer| balances[customer].to_d.zero? }
                else
                  customers
                end
    sorted_customers = customers.sort_by { |customer| -balances[customer].to_d }
    @customer_balances = balances.transform_keys(&:id)
    @pagy, @customers = pagy_array(sorted_customers)

    # Para el <select> de filtros
    @suppliers = Supplier.order(:name).pluck(:name, :id)
  end

  def group
    @group = CustomerGroups.find_by_name(params[:name], Customer.all)
    unless @group
      redirect_to customers_path, alert: "Grupo no encontrado" and return
    end

    customer_ids = @group[:customers].map(&:id)
    @group_search_query = params[:q].to_s.strip
    filtered_customer_ids =
      if @group_search_query.present?
        @group[:customers].select { |c| c.name.downcase.include?(@group_search_query.downcase) }.map(&:id)
      else
        customer_ids
      end
    @display_customers = @group[:customers].select { |c| filtered_customer_ids.include?(c.id) }

    base_sales_scope = Sale.where(customer_id: filtered_customer_ids)
    sales_scope = base_sales_scope.includes(:supplier, :customer, :sales_users, :transfers)

    @group_total_deposit = base_sales_scope.sum(:gross_deposit).to_d
    @group_total_after_pcts = sales_scope.sum { |s| s.net_after_provider_and_sellers.to_d }
    @group_total_transferred = sales_scope.sum do |s|
      s.transfers.where(to_entity_type: "Supplier").sum(:amount).to_d
    end
    @group_opening_balance = OpeningBalance.total_for_group(@group[:name])
    direct_outgoing = Hash.new(0.to_d)
    Transfer.where(sale_id: nil, from_entity_type: "Customer", from_entity_id: filtered_customer_ids).find_each do |transfer|
      direct_outgoing[transfer.from_entity_id] += transfer.total_outgoing
    end

    incoming_from_customers = Transfer.where(
      sale_id: nil,
      to_entity_type: "Customer",
      to_entity_id: filtered_customer_ids,
      from_entity_type: "Customer"
    ).group(:to_entity_id).sum(:amount)

    incoming_from_others = Transfer.where(
      sale_id: nil,
      to_entity_type: "Customer",
      to_entity_id: filtered_customer_ids
    ).where.not(from_entity_type: "Customer").group(:to_entity_id).sum(:amount)

    direct_to_customers = incoming_from_others.values.sum.to_d
    direct_to_group = Transfer.where(
      to_entity_type: "CustomerGroup",
      sale_id: nil
    ).where("lower(to_group) = ?", @group[:name].downcase).sum(:amount).to_d

    sale_transfers_to_customers = Transfer
      .where(sale_id: base_sales_scope.select(:id))
      .where(to_entity_type: "Customer", to_entity_id: filtered_customer_ids)
      .sum(:amount)
      .to_d
    sale_transfers_to_group = Transfer
      .where(sale_id: base_sales_scope.select(:id))
      .where(to_entity_type: "CustomerGroup")
      .where("lower(to_group) = ?", @group[:name].downcase)
      .sum(:amount)
      .to_d

    @group_total_received = direct_to_customers + direct_to_group + sale_transfers_to_customers + sale_transfers_to_group
    direct_from_customers_total = incoming_from_customers.values.sum.to_d
    direct_outgoing_total = direct_outgoing.values.sum.to_d
    @group_available_balance = @group_total_after_pcts + @group_opening_balance - @group_total_transferred -
                               @group_total_received - direct_outgoing_total + direct_from_customers_total

    @per_customer_deposit = Hash.new(0)
    @per_customer_after_pcts = Hash.new(0)
    @per_customer_transfers = Hash.new(0)
    @per_customer_direct_received = Hash.new(0)
    @per_customer_balances = Hash.new(0)

    sales_by_customer = sales_scope.group_by(&:customer_id)
    opening_by_customer = OpeningBalance.customers
                                        .where(reference_id: filtered_customer_ids)
                                        .group(:reference_id)
                                        .sum(:amount)

    @display_customers.each do |customer|
      cid = customer.id
      sales = sales_by_customer[cid] || []
      gross_total = sales.sum { |s| s.gross_deposit.to_d }
      net_total = sales.sum { |s| s.net_after_provider_and_sellers.to_d }
      transfers_total = sales.sum { |s| s.total_transfer_applied.to_d }
      opening = opening_by_customer[cid].to_d
      @per_customer_deposit[cid] = gross_total
      @per_customer_after_pcts[cid] = net_total
      @per_customer_transfers[cid] = transfers_total
      direct_received = incoming_from_others[cid].to_d
      direct_from_customers = incoming_from_customers[cid].to_d
      direct_out = direct_outgoing[cid].to_d
      @per_customer_direct_received[cid] = direct_received
      @per_customer_balances[cid] = net_total + opening - transfers_total - direct_received - direct_out + direct_from_customers
    end

    @sales = sales_scope.order(date: :desc).limit(50)

    @group_transfers = transfers_for_group(@group[:name], filtered_customer_ids)
    @group_transfer_labels = @group_transfers.index_with do |t|
      {
        from: entity_label_for(t, :from),
        to: entity_label_for(t, :to)
      }
    end

    @pagy, @group_customers = pagy_array(@display_customers)
  end

  def show
    @suppliers = @customer.suppliers.order(:name)

    base_sales_scope = @customer.sales
    sales_scope = base_sales_scope.includes(:supplier, :sales_users, :transfers)
    @sales = sales_scope.order(date: :desc).limit(25)

    @customer_total_deposit = base_sales_scope.sum(:gross_deposit).to_d
    @customer_total_after_pcts = sales_scope.sum { |s| s.net_after_provider_and_sellers.to_d }
    @customer_total_transferred = sales_scope.sum { |s| s.total_transfer_applied.to_d }
    @customer_opening_balance = OpeningBalance.total_for_customer(@customer.id)

    # Transfers recibidos directamente (sin venta) que reducen lo adeudado
    @customer_direct_received = Transfer.customer_incoming_from_others_total(@customer.id)
    @customer_available_balance = @customer.available_transfer_total

    @customer_transfers = Transfer
                            .includes(:supplier, :sale)
                            .where(
                              "(from_entity_type = ? AND from_entity_id = ?) OR (to_entity_type = ? AND to_entity_id = ?)",
                              "Customer",
                              @customer.id,
                              "Customer",
                              @customer.id
                            )
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

  def update_opening_balance
    balance = OpeningBalance.find_or_initialize_by(
      reference_type: OpeningBalance::TYPES[:customer],
      reference_id: @customer.id
    )
    balance.amount = opening_balance_params[:amount]
    balance.source = "manual"

    if balance.save
      redirect_to customer_path(@customer), notice: "Saldo inicial actualizado."
    else
      redirect_to customer_path(@customer), alert: balance.errors.full_messages.to_sentence
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
    params.require(:customer).permit(
      :code,
      :name,
      :default_customer_fee_pct,
      customer_suppliers_attributes: [ :id, :supplier_id, :customer_fee_pct ],
      commission_defaults_attributes: [ :id, :supplier_id, :user_id, :commission_pct ]
    )
  end

  def opening_balance_params
    params.fetch(:opening_balance, {}).permit(:amount)
  end

  def load_form_collections
    @suppliers = Supplier.order(:name)
    @users = User.order(:name)
  end

  def build_default_associations
    @customer.customer_suppliers.build if @customer.customer_suppliers.empty?
    @customer.commission_defaults.build if @customer.commission_defaults.empty?
  end

  def transfers_for_group(group_name, customer_ids)
    return Transfer.none if group_name.blank?
    target = group_name.to_s.downcase
    ids = customer_ids.presence || [ 0 ]
    Transfer
      .where(
        "(to_entity_type = ? AND lower(to_group) = ?) OR " \
        "(from_entity_type = ? AND lower(from_group) = ?) OR " \
        "(from_entity_type = ? AND from_entity_id IN (?)) OR " \
        "(to_entity_type = ? AND to_entity_id IN (?))",
        "CustomerGroup", target,
        "CustomerGroup", target,
        "Customer", ids,
        "Customer", ids
      )
      .order(occurred_at: :desc)
  end

  def entity_label_for(transfer, side)
    type = transfer.send("#{side}_entity_type")
    return "" if type.blank?

    case type
    when "CustomerGroup"
      "Grupo #{transfer.send("#{side}_group")}"
    when "Customer", "Supplier", "User"
      entity = transfer.send("#{side}_entity")
      name = entity&.name || entity&.email || entity&.code
      name.presence || "#{type} ##{transfer.send("#{side}_entity_id")}"
    else
      "#{type} #{transfer.send("#{side}_entity_id")}"
    end
  end
end
