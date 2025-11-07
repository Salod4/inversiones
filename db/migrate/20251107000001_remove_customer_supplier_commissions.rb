# frozen_string_literal: true

class RemoveCustomerSupplierCommissions < ActiveRecord::Migration[8.0]
  def up
    drop_table :customer_supplier_commissions, if_exists: true

    execute <<~SQL
      UPDATE customer_suppliers
      SET customer_fee_pct = default_customer_fee_pct
      WHERE customer_fee_pct IS NULL AND default_customer_fee_pct IS NOT NULL;
    SQL

    if column_exists?(:customer_suppliers, :default_customer_fee_pct)
      remove_column :customer_suppliers, :default_customer_fee_pct
    end
  end

  def down
    unless table_exists?(:customer_supplier_commissions)
      create_table :customer_supplier_commissions do |t|
        t.references :supplier, null: false, foreign_key: true
        t.references :customer, null: false, foreign_key: true
        t.references :user, foreign_key: true
        t.string :role, null: false
        t.decimal :pct, precision: 6, scale: 4, default: 0, null: false
        t.timestamps
      end

      add_index :customer_supplier_commissions,
                [ :supplier_id, :customer_id, :role ],
                unique: true,
                name: "idx_unique_commission_role_per_pair"

      execute <<~SQL
        ALTER TABLE customer_supplier_commissions
        ADD CONSTRAINT chk_csc_pct_range
        CHECK (pct >= 0 AND pct < 1);
      SQL
    end

    add_column :customer_suppliers, :default_customer_fee_pct,
               :decimal, precision: 6, scale: 4, default: 0, null: false

    execute <<~SQL
      UPDATE customer_suppliers
      SET default_customer_fee_pct = COALESCE(customer_fee_pct, 0);
    SQL
  end
end
