class Customer < ApplicationRecord
  has_many :sales, dependent: :restrict_with_error
  has_many :transfers, dependent: :restrict_with_error
  has_many :customer_closings, dependent: :restrict_with_error
  has_many :customer_suppliers, dependent: :destroy
  has_many :suppliers, through: :customer_suppliers
  has_many :commission_defaults, dependent: :destroy
  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :default_customer_fee_pct,
            numericality: { greater_than_or_equal_to: 0, less_than: 1 },
            allow_nil: true

  def total_working_capital
    sales.sum(:working_capital).to_d
  end

  def total_customer_balance
    sales.sum(:customer_balance).to_d + OpeningBalance.total_for_customer(id)
  end

  def available_transfer_total(excluding: nil)
    total_balance = total_customer_balance
    extra_transfers = transfers.where(sale_id: nil)
    extra_transfers = extra_transfers.where.not(id: excluding.id) if excluding&.persisted?
    total_balance - extra_transfers.sum(:amount).to_d
  end

  def self.ransackable_attributes(_auth = nil)
    %w[id code name created_at updated_at]
  end

  def self.ransackable_associations(_auth = nil)
    %w[suppliers customer_suppliers sales]
  end
end
