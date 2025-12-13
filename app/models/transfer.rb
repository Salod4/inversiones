class Transfer < ApplicationRecord
  ALLOWED_ENTITY_TYPES = %w[Customer Supplier User CustomerGroup].freeze

  belongs_to :customer, optional: true
  belongs_to :sale, optional: true
  belongs_to :supplier, optional: true

  belongs_to :from_entity, polymorphic: true, optional: true
  belongs_to :to_entity, polymorphic: true, optional: true

  validates :amount, numericality: { greater_than: 0 }
  validates :from_entity_type, :to_entity_type, presence: true
  validates :from_entity_id, presence: true, unless: -> { from_entity_type == "CustomerGroup" }
  validates :to_entity_id, presence: true, unless: -> { to_entity_type == "CustomerGroup" }
  validates :from_group, presence: true, if: -> { from_entity_type == "CustomerGroup" }
  validates :to_group, presence: true, if: -> { to_entity_type == "CustomerGroup" }
  validates :from_entity_type, :to_entity_type, inclusion: { in: ALLOWED_ENTITY_TYPES }
  validates :payment_method, inclusion: { in: %w[deposito efectivo] }
  validate :amount_does_not_exceed_sale_balance
  validate :customer_matches_sale
  validate :supplier_matches_sale
  validate :entities_are_distinct
  validate :entities_match_types

  before_validation :assign_defaults, on: :create
  before_validation :backfill_parties_from_sale
  before_validation :sync_customer_and_supplier_from_entities
  after_commit :sync_sale_balances, on: [ :create, :update, :destroy ]

  def entity_label(side)
    type = send("#{side}_entity_type")
    return "" if type.blank?

    case type
    when "CustomerGroup"
      "Grupo #{send("#{side}_group")}"
    when "Customer", "Supplier", "User"
      ent = safe_entity(side)
      ent&.name || ent&.email || ent&.code || "#{type} ##{send("#{side}_entity_id")}"
    else
      "#{type} #{send("#{side}_entity_id")}"
    end
  end

  private

  def safe_entity(side)
    type = send("#{side}_entity_type")
    return nil if type == "CustomerGroup"
    send("#{side}_entity")
  end

  def amount_does_not_exceed_sale_balance
    return if sale.blank? || amount.blank?

    available = sale.available_transfer_amount(excluding: self)
    return if amount <= available

    errors.add(:amount, "supera el saldo disponible de #{available.to_s("F")}")
  end

  def customer_matches_sale
    return if sale.blank? || customer_id.blank?
    return if sale.customer_id == customer_id

    errors.add(:customer_id, "debe coincidir con el cliente de la venta")
  end

  def supplier_matches_sale
    return if sale.blank? || supplier.blank?
    return if sale.supplier_id == supplier_id

    errors.add(:supplier_id, "debe coincidir con el proveedor asignado a la venta")
  end

  def entities_are_distinct
    return unless from_entity_type.present? && to_entity_type.present?
    return unless from_entity_type == to_entity_type

    if from_entity_type == "CustomerGroup"
      if from_group.present? && to_group.present? && from_group.casecmp?(to_group)
        errors.add(:base, "El origen y destino no pueden ser iguales")
      end
    elsif from_entity_id.present? && to_entity_id.present? && from_entity_id == to_entity_id
      errors.add(:base, "El origen y destino no pueden ser iguales")
    end
  end

  def entities_match_types
    validate_entity_type(from_entity_type, from_entity_id, from_group, :from_entity_id, :from_group)
    validate_entity_type(to_entity_type, to_entity_id, to_group, :to_entity_id, :to_group)
  end

  def validate_entity_type(type, id, group, id_field, group_field)
    return if type.blank?

    case type
    when "Customer"
      errors.add(id_field, "no es un cliente válido") unless id.present? && Customer.exists?(id)
    when "Supplier"
      errors.add(id_field, "no es un proveedor válido") unless id.present? && Supplier.exists?(id)
    when "User"
      errors.add(id_field, "no es un vendedor válido") unless id.present? && User.exists?(id)
    when "CustomerGroup"
      valid = group.present? && CustomerGroups.names.any? { |name| name.casecmp?(group.to_s) }
      errors.add(group_field, "no es un grupo válido") unless valid
    else
      errors.add(id_field, "tipo inválido")
    end
  end

  def sync_sale_balances
    return unless sale

    sale.refresh_transfer_totals!
  end

  def assign_defaults
    self.customer ||= sale&.customer
    self.supplier ||= sale&.supplier
    self.payment_method ||= "deposito"
    self.occurred_at ||= begin
      business_date = Closing.open_business_date(Time.zone.today)
      now = Time.zone.now
      now.change(year: business_date.year, month: business_date.month, day: business_date.day)
    end
    assign_code if code.blank?
  end

  def backfill_parties_from_sale
    return if from_entity_type.present? && to_entity_type.present?
    if sale
      self.from_entity = sale.customer if from_entity.blank? && sale.customer
      self.to_entity = sale.supplier if to_entity.blank? && sale.supplier
    else
      self.from_entity ||= customer if customer
      self.to_entity ||= supplier if supplier
    end
  end

  def sync_customer_and_supplier_from_entities
    from_ent = safe_entity(:from)
    to_ent = safe_entity(:to)

    if from_ent.is_a?(Customer)
      self.customer ||= from_ent
    elsif to_ent.is_a?(Customer)
      self.customer ||= to_ent
    end

    if from_ent.is_a?(Supplier)
      self.supplier ||= from_ent
    elsif to_ent.is_a?(Supplier)
      self.supplier ||= to_ent
    end
  end

  def assign_code
    supplier_code = supplier&.code || sale&.supplier&.code || "SUP"
    sale_code = sale&.code || sale_id
    stamp = Time.zone.today.strftime("%-d%b").upcase
    if payment_method == "efectivo"
      from_code = entity_code(safe_entity(:from)) || "ORIG"
      to_code = entity_code(safe_entity(:to)) || "DEST"
      base_code = "EFE-#{from_code}-#{to_code}-#{stamp}"
    else
      base_code = "SPEI-#{sale_code}-#{supplier_code}-#{stamp}"
    end
    self.code = unique_code(base_code)
  end

  def unique_code(base)
    candidate = base
    counter = 2
    while Transfer.exists?(code: candidate)
      candidate = "#{base}-#{counter}"
      counter += 1
    end
    candidate
  end

  def entity_code(entity)
    return unless entity
    entity.respond_to?(:code) ? entity.code.presence : nil
  end
end
