# frozen_string_literal: true

class Sale < ApplicationRecord
  MAX_SELLERS = 3

  belongs_to :customer
  belongs_to :supplier
  belongs_to :closing, optional: true

  has_many :sales_users, dependent: :destroy
  has_many :users, through: :sales_users
  has_many :transfers, dependent: :restrict_with_error

  accepts_nested_attributes_for :sales_users, allow_destroy: true

  validates :status, inclusion: { in: %w[open closed canceled] }, allow_nil: true
  validates :gross_deposit, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :provider_pct, numericality: { greater_than_or_equal_to: 0, less_than: 1 }, allow_nil: true
  validates :customer_fee_pct,
            numericality: { greater_than_or_equal_to: 0, less_than: 1 },
            allow_nil: true
  validates :provider_pct_override,
            numericality: { greater_than_or_equal_to: 0, less_than: 1 },
            allow_nil: true
  validates :customer_fee_pct_override,
            numericality: { greater_than_or_equal_to: 0, less_than: 1 },
            allow_nil: true

  validate :seller_limit

  def seller_limit
    active_sales_users = sales_users.reject(&:marked_for_destruction?)
    if active_sales_users.size > MAX_SELLERS
      errors.add(:sales_users, "exceeds the maximum of #{MAX_SELLERS} sellers per sale")
    end
  end

  def total_seller_commission
    (sales_users.sum(:commission_amount) || 0)
  end

  def net_after_provider_and_sellers
    (gross_deposit || 0) - (provider_commission || 0) - total_seller_commission
  end

  def balance_after_transfers
    net_after_provider_and_sellers - (total_transfer_applied || 0)
  end

  def resolved_provider_pct
    provider_pct_override.presence || provider_pct.to_f
  end

  def resolved_customer_fee_pct
    customer_fee_pct_override.presence || customer_fee_pct.to_f
  end
end
