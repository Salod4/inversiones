class Transfer < ApplicationRecord
  ALLOWED_ENTITY_TYPES = %w[Customer Supplier User].freeze

  belongs_to :customer, optional: true
  belongs_to :sale, optional: true
  belongs_to :supplier, optional: true

  belongs_to :from_entity, polymorphic: true
  belongs_to :to_entity, polymorphic: true

  validates :amount, numericality: { greater_than: 0 }
  validates :from_entity_type, :from_entity_id, :to_entity_type, :to_entity_id, presence: true
  validates :from_entity_type, :to_entity_type, inclusion: { in: ALLOWED_ENTITY_TYPES }
  validate :amount_does_not_exceed_sale_balance
  validate :customer_matches_sale
  validate :supplier_matches_sale
  validate :entities_are_distinct
  validate :entities_match_types

  before_validation :assign_defaults, on: :create
  before_validation :backfill_parties_from_sale
  before_validation :sync_customer_and_supplier_from_entities
  after_commit :sync_sale_balances, on: [ :create, :update, :destroy ]

  private

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
    if from_entity_type == to_entity_type && from_entity_id == to_entity_id
      errors.add(:base, "El origen y destino no pueden ser iguales")
    end
  end

  def entities_match_types
    validate_entity_type(from_entity_type, from_entity_id, :from_entity_id)
    validate_entity_type(to_entity_type, to_entity_id, :to_entity_id)
  end

  def validate_entity_type(type, id, field)
    return if type.blank? || id.blank?
    case type
    when "Customer"
      errors.add(field, "no es un cliente válido") unless Customer.exists?(id)
    when "Supplier"
      errors.add(field, "no es un proveedor válido") unless Supplier.exists?(id)
    when "User"
      errors.add(field, "no es un vendedor válido") unless User.exists?(id)
    else
      errors.add(field, "tipo inválido")
    end
  end

  def sync_sale_balances
    return unless sale

    sale.refresh_transfer_totals!
  end

  def assign_defaults
    self.customer ||= sale&.customer
    self.supplier ||= sale&.supplier
    self.occurred_at ||= Time.current
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
    if from_entity.is_a?(Customer)
      self.customer ||= from_entity
    elsif to_entity.is_a?(Customer)
      self.customer ||= to_entity
    end

    if from_entity.is_a?(Supplier)
      self.supplier ||= from_entity
    elsif to_entity.is_a?(Supplier)
      self.supplier ||= to_entity
    end
  end

  def assign_code
    supplier_code = supplier&.code || sale&.supplier&.code || "SUP"
    sale_code = sale&.code || sale_id
    stamp = Time.zone.today.strftime("%-d%b").upcase
    base_code = "SPEI-#{sale_code}-#{supplier_code}-#{stamp}"
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
end
