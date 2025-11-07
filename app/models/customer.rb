class Customer < ApplicationRecord
  has_many :sales, dependent: :restrict_with_error
  has_many :customer_closings, dependent: :restrict_with_error
  has_many :customer_suppliers, dependent: :destroy
  has_many :suppliers, through: :customer_suppliers
  has_many :commission_defaults, dependent: :destroy
  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :default_customer_fee_pct,
            numericality: { greater_than_or_equal_to: 0, less_than: 1 },
            allow_nil: true
end
