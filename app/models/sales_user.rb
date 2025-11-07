class SalesUser < ApplicationRecord
  belongs_to :sale
  belongs_to :user

  validates :commission_pct, numericality: { greater_than_or_equal_to: 0, less_than: 1 }
  validates :commission_pct_override,
            numericality: { greater_than_or_equal_to: 0, less_than: 1 },
            allow_nil: true
  validates :commission_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_save :backfill_commission_amount

  def effective_commission_pct
    commission_pct_override.presence || commission_pct
  end

  private

  def backfill_commission_amount
    return unless commission_amount.blank?
    pct = effective_commission_pct
    return unless pct.present? && sale&.net_base.present?

    self.commission_amount = (sale.net_base * pct).round(2)
  end
end
