class Transfer < ApplicationRecord
  belongs_to :customer
  belongs_to :sale, optional: true
  belongs_to :supplier

  validates :amount, numericality: { greater_than: 0 }
  validate :amount_does_not_exceed_sale_balance
  validate :customer_matches_sale
  validate :supplier_matches_sale

  before_validation :assign_defaults, on: :create
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
