class Customer < ApplicationRecord
  has_many :sales, dependent: :restrict_with_error
  has_many :transfers, dependent: :restrict_with_error
  has_many :customer_closings, dependent: :restrict_with_error
  has_many :customer_suppliers, dependent: :destroy
  has_many :suppliers, through: :customer_suppliers
  has_many :commission_defaults, dependent: :destroy
  accepts_nested_attributes_for :customer_suppliers, reject_if: :reject_customer_supplier_row
  accepts_nested_attributes_for :commission_defaults, reject_if: :reject_commission_default_row
  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :default_customer_fee_pct,
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: true

  def total_working_capital
    sales.sum(:working_capital).to_d
  end

  def total_customer_balance
    sales.sum(:customer_balance).to_d + OpeningBalance.total_for_customer(id)
  end

  def available_transfer_total(excluding: nil)
    total_balance = total_customer_balance
    outgoing = Transfer.customer_outgoing_total(id, excluding: excluding)
    incoming_from_customers = Transfer.customer_incoming_from_customers_total(id, excluding: excluding)
    incoming_from_others = Transfer.customer_incoming_from_others_total(id, excluding: excluding)
    total_balance - outgoing - incoming_from_others + incoming_from_customers
  end

  def self.ransackable_attributes(_auth = nil)
    %w[id code name created_at updated_at]
  end

  def self.ransackable_associations(_auth = nil)
    %w[suppliers customer_suppliers sales]
  end

  private

  def reject_customer_supplier_row(attrs)
    attrs["supplier_id"].blank? || attrs["customer_fee_pct"].blank?
  end

  def reject_commission_default_row(attrs)
    attrs["supplier_id"].blank? || attrs["user_id"].blank? || attrs["commission_pct"].blank?
  end
end
