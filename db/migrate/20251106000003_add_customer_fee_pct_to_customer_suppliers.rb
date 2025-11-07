# frozen_string_literal: true

class AddCustomerFeePctToCustomerSuppliers < ActiveRecord::Migration[8.0]
  def change
    add_column :customer_suppliers, :customer_fee_pct, :decimal, precision: 6, scale: 4

    execute <<~SQL
      ALTER TABLE customer_suppliers
      ADD CONSTRAINT customer_suppliers_fee_range
      CHECK (customer_fee_pct IS NULL OR (customer_fee_pct >= 0 AND customer_fee_pct < 1));
    SQL
  end
end
