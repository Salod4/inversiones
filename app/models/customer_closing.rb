class CustomerClosing < ApplicationRecord
  belongs_to :closing
  belongs_to :customer

  validates :customer_balance, numericality: true, allow_nil: true
  validates :receivables, numericality: true, allow_nil: true
end
