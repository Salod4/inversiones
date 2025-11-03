class CustomerSupplier < ApplicationRecord
belongs_to :customer,  class_name: "Customer",  foreign_key: :customer_id,  inverse_of: :customer_suppliers
  belongs_to :supplier,  class_name: "Supplier",  foreign_key: :supplier_id,  inverse_of: :customer_suppliers

  validates :customer_id, uniqueness: { scope: :supplier_id }
end
