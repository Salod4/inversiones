# frozen_string_literal: true

class CustomerSupplierVendor < ApplicationRecord
  belongs_to :customer_supplier, inverse_of: :customer_supplier_vendors
  belongs_to :user, inverse_of: :customer_supplier_vendors

  validates :commission_pct, numericality: { greater_than_or_equal_to: 0, less_than: 1 }
end
