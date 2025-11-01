class Closing < ApplicationRecord
  has_many :sales, dependent: :nullify
  has_many :customer_closings, dependent: :destroy
  has_many :supplier_closings, dependent: :destroy

  validates :business_date, presence: true
  validates :status, inclusion: { in: %w[open closed] }
end
