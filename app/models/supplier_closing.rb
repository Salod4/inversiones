class SupplierClosing < ApplicationRecord
  belongs_to :closing
  belongs_to :supplier

  validates :supplier_credit, numericality: true, allow_nil: true
  validates :amount_owed_to_supplier, numericality: true, allow_nil: true
end
