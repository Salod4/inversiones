# frozen_string_literal: true

class OpeningBalance < ApplicationRecord
  TYPES = {
    customer: "customer",
    customer_group: "customer_group",
    supplier: "supplier",
    user: "user"
  }.freeze

  validates :reference_type, inclusion: { in: TYPES.values }
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validate :reference_presence

  scope :customers, -> { where(reference_type: TYPES[:customer]) }
  scope :customer_groups, -> { where(reference_type: TYPES[:customer_group]) }
  scope :suppliers, -> { where(reference_type: TYPES[:supplier]) }
  scope :users, -> { where(reference_type: TYPES[:user]) }

  def self.total_for_customer(customer_id)
    customers.where(reference_id: customer_id).sum(:amount).to_d
  end

  def self.total_for_group(name)
    return 0.to_d if name.blank?
    customer_groups.where("lower(group_name) = ?", name.downcase).sum(:amount).to_d
  end

  def self.total_for_supplier(supplier_id)
    suppliers.where(reference_id: supplier_id).sum(:amount).to_d
  end

  def self.total_for_user(user_id)
    users.where(reference_id: user_id).sum(:amount).to_d
  end

  private

  def reference_presence
    if reference_type == TYPES[:customer_group]
      errors.add(:group_name, "no puede estar vacío") if group_name.blank?
    else
      errors.add(:reference_id, "no puede estar vacío") if reference_id.blank?
    end
  end
end
