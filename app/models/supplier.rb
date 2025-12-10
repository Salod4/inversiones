class Supplier < ApplicationRecord
  has_many :sales, dependent: :restrict_with_error
  has_many :supplier_closings, dependent: :restrict_with_error
  has_many :transfers, dependent: :restrict_with_error
  has_many :customer_suppliers, dependent: :destroy
  has_many :customers, through: :customer_suppliers
  has_many :commission_defaults, dependent: :destroy



  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :default_analysis_pct,
            numericality: { greater_than_or_equal_to: 0, less_than: 1 },
            allow_nil: true

  def available_transfer_total
    ret_comp_total = sales.sum(Arel.sql("COALESCE(gross_deposit,0) - COALESCE(provider_commission,0)")).to_d
    transferred = transfers.sum(:amount).to_d
    ret_comp_total - transferred
  end

  def self.ransackable_attributes(_auth = nil)
    %w[id code name created_at updated_at]
  end

  def self.ransackable_associations(_auth = nil)
    %w[customers customer_suppliers sales]
  end
end
