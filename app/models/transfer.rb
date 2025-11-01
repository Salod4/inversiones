class Transfer < ApplicationRecord
  belongs_to :sale
  belongs_to :supplier

  validates :amount, numericality: { greater_than: 0 }
end
