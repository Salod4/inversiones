class Transfer < ApplicationRecord
  belongs_to :sale
  belongs_to :supplier

  validates :amount, numericality: { greater_than: 0 }

  before_validation :assign_defaults, on: :create

  private

  def assign_defaults
    self.occurred_at ||= Time.current
    assign_code if code.blank?
  end

  def assign_code
    supplier_code = supplier&.code || sale&.supplier&.code || "SUP"
    sale_code = sale&.code || sale_id
    stamp = Time.zone.today.strftime("%-d%b").upcase
    self.code = "SPEI-#{sale_code}-#{supplier_code}-#{stamp}"
  end
end
