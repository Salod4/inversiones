class Loan < ApplicationRecord
  has_many :loan_payments, dependent: :destroy

  before_validation :default_totals

  validates :name, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :total_paid, numericality: { greater_than_or_equal_to: 0 }
  validate :paid_not_exceed_amount

  def balance
    amount.to_d - total_paid.to_d
  end

  def recalc_totals!
    totals = loan_payments.sum(:amount)
    last_paid = loan_payments.order(paid_at: :desc, created_at: :desc).limit(1).pick(:paid_at)
    update_columns(total_paid: totals, last_payment_at: last_paid) # rubocop:disable Rails/SkipsModelValidations
  end

  private

  def default_totals
    self.total_paid = 0 if total_paid.nil?
  end

  def paid_not_exceed_amount
    return if amount.blank? || total_paid.blank?
    errors.add(:total_paid, "no puede ser mayor al monto") if total_paid.to_d > amount.to_d
  end
end
