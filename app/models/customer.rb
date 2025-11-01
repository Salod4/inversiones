class Customer < ApplicationRecord
  has_many :sales, dependent: :restrict_with_error
  has_many :customer_closings, dependent: :restrict_with_error

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :default_customer_fee_pct,
            numericality: { greater_than_or_equal_to: 0, less_than: 1 },
            allow_nil: true
end
