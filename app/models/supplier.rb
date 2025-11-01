class Supplier < ApplicationRecord
  has_many :sales, dependent: :restrict_with_error
  has_many :supplier_closings, dependent: :restrict_with_error
  has_many :transfers, dependent: :restrict_with_error

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :default_analysis_pct,
            numericality: { greater_than_or_equal_to: 0, less_than: 1 },
            allow_nil: true
end
