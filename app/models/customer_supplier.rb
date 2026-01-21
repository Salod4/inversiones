class CustomerSupplier < ApplicationRecord
  belongs_to :customer, class_name: "Customer", foreign_key: :customer_id, inverse_of: :customer_suppliers
  belongs_to :supplier, class_name: "Supplier", foreign_key: :supplier_id, inverse_of: :customer_suppliers

  has_many :customer_supplier_vendors, dependent: :destroy, inverse_of: :customer_supplier
  accepts_nested_attributes_for :customer_supplier_vendors,
                                reject_if: :reject_vendor_row,
                                allow_destroy: true

  validates :customer_id, uniqueness: { scope: :supplier_id }

  private

  def reject_vendor_row(attrs)
    user_id = attrs["user_id"] || attrs[:user_id]
    commission_pct = attrs["commission_pct"] || attrs[:commission_pct]
    user_id.blank? || commission_pct.blank?
  end
end
