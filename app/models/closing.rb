class Closing < ApplicationRecord
  has_many :sales, dependent: :nullify
  has_many :customer_closings, dependent: :destroy
  has_many :supplier_closings, dependent: :destroy

  validates :business_date, presence: true
  validates :status, inclusion: { in: %w[open closed] }
   scope :for_date, ->(date) { where(business_date: date) }

  def self.closed_for?(date)
    for_date(date).exists?
  end
  def self.open_business_date(today = Date.current)
    date = today
    90.times do
      return date unless closed_for?(date)
      date += 1.day
    end
    date
  end
end
