class CustomerSupplier < ApplicationRecord
  belongs_to :customer_id
  belongs_to :supplier_id
  validates :customer_id, uniqueness: { scope: :supplier_id }
end
