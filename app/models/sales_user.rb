class SalesUser < ApplicationRecord
  belongs_to :sale
  belongs_to :user

  validates :commission_pct, numericality: { greater_than_or_equal_to: 0, less_than: 1 }
  validates :commission_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
