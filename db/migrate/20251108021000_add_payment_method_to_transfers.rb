# frozen_string_literal: true

class AddPaymentMethodToTransfers < ActiveRecord::Migration[8.0]
  def change
    add_column :transfers, :payment_method, :string, default: "deposito", null: false
  end
end
