# frozen_string_literal: true

class CommissionDefault < ApplicationRecord
  belongs_to :supplier
  belongs_to :customer
  belongs_to :user

  validates :commission_pct, numericality: { greater_than_or_equal_to: 0, less_than: 1 }
end
