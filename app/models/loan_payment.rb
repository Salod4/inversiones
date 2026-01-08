class LoanPayment < ApplicationRecord
  belongs_to :loan

  before_validation :set_paid_at

  validates :amount, numericality: { greater_than: 0 }
  validate :not_overpay

  after_commit :refresh_loan_totals, on: [ :create, :destroy ]

  private

  def set_paid_at
    self.paid_at ||= Time.zone.now
  end

  def not_overpay
    return if loan.blank? || amount.blank?
    errors.add(:amount, "excede el saldo pendiente") if amount.to_d > loan.balance
  end

  def refresh_loan_totals
    return if loan.blank? || loan.destroyed?
    loan.recalc_totals!
  end
end
