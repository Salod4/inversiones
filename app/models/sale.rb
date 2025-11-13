# frozen_string_literal: true

require "bigdecimal"

class Sale < ApplicationRecord
  MAX_SELLERS = 4

  before_validation :assign_defaults, on: :create

  belongs_to :customer
  belongs_to :supplier
  belongs_to :closing, optional: true

  has_many :sales_users, dependent: :destroy
  has_many :users, through: :sales_users
  has_many :transfers, dependent: :restrict_with_error

  accepts_nested_attributes_for :sales_users, allow_destroy: true
  before_validation :assign_business_date
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

  def total_transfer_applied
    transfers.sum(:amount)
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

  def available_transfer_amount(excluding: nil)
    scope = transfers
    scope = scope.where.not(id: excluding.id) if excluding&.persisted?
    used = scope.sum(:amount) || 0
    remaining = decimal(gross_deposit) - used
    remaining.positive? ? remaining : BigDecimal("0")
  end

  def refresh_transfer_totals!
    transfer_sum = transfers.sum(:amount) || 0
    new_customer_balance = (decimal(working_capital) - transfer_sum).round(2)
    update_columns(
      total_transfer_applied: transfer_sum,
      customer_balance: new_customer_balance,
      updated_at: Time.current
    )
  end

  private

  def decimal(value)
    BigDecimal(value.presence || 0)
  end

  def assign_defaults
    self.date ||= Date.current
    assign_code if code.blank?
  end

  def assign_code
    return if supplier.blank?

    next_seq = Sale.where(supplier_id: supplier_id).count + 1
    date_stamp = (date || Date.current).strftime("%-d%b").upcase
    supplier_code = supplier.code.presence || "SUP"

    self.code = "MOV-#{supplier_code}-##{next_seq}-#{date_stamp}"
  end

  def assign_business_date
    target = Closing.open_business_date(Date.current)
    self.date = target if date.blank? || date == Date.current
  end
end
