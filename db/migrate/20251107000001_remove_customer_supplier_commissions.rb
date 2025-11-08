# frozen_string_literal: true

class RemoveCustomerSupplierCommissions < ActiveRecord::Migration[8.0]
  def up
    backfill_customer_fee_pct
    drop_default_customer_fee_pct_column
    drop_legacy_commissions_table
  end

  def down
    recreate_default_customer_fee_pct_column
    recreate_customer_supplier_commissions_table
  end

  private

  def backfill_customer_fee_pct
    if column_exists?(:customer_suppliers, :default_customer_fee_pct)
      execute <<~SQL
        UPDATE customer_suppliers
        SET customer_fee_pct = default_customer_fee_pct
        WHERE customer_fee_pct IS NULL
          AND default_customer_fee_pct IS NOT NULL;
      SQL
      return
    end

    return unless legacy_commission_table_usable?

    execute <<~SQL
      UPDATE customer_suppliers cs
      SET customer_fee_pct = csc.customer_fee_pct
      FROM customer_supplier_commissions csc
      WHERE cs.customer_id = csc.customer_id
        AND cs.supplier_id = csc.supplier_id
        AND cs.customer_fee_pct IS NULL
        AND csc.customer_fee_pct IS NOT NULL;
    SQL
  end

  def drop_default_customer_fee_pct_column
    return unless column_exists?(:customer_suppliers, :default_customer_fee_pct)

    remove_column :customer_suppliers, :default_customer_fee_pct
  end

  def drop_legacy_commissions_table
    return unless table_exists?(:customer_supplier_commissions)

    drop_table :customer_supplier_commissions
  end

  def recreate_default_customer_fee_pct_column
    unless column_exists?(:customer_suppliers, :default_customer_fee_pct)
      add_column :customer_suppliers, :default_customer_fee_pct,
                 :decimal, precision: 6, scale: 4
    end

    return unless column_exists?(:customer_suppliers, :default_customer_fee_pct)

    execute <<~SQL
      UPDATE customer_suppliers
      SET default_customer_fee_pct = customer_fee_pct
      WHERE customer_fee_pct IS NOT NULL;
    SQL
  end

  def recreate_customer_supplier_commissions_table
    return if table_exists?(:customer_supplier_commissions)

    create_table :customer_supplier_commissions do |t|
      t.references :supplier, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :role
      t.decimal :customer_fee_pct, precision: 6, scale: 4
      t.timestamps
    end

    add_index :customer_supplier_commissions,
              [ :supplier_id, :customer_id ],
              unique: true,
              name: "idx_unique_commission_pair"

    execute <<~SQL
      ALTER TABLE customer_supplier_commissions
      ADD CONSTRAINT chk_csc_customer_fee_pct_range
      CHECK (
        customer_fee_pct IS NULL
        OR (customer_fee_pct >= 0 AND customer_fee_pct < 1)
      );
    SQL
  end

  def legacy_commission_table_usable?
    table_exists?(:customer_supplier_commissions) &&
      column_exists?(:customer_supplier_commissions, :customer_id) &&
      column_exists?(:customer_supplier_commissions, :supplier_id) &&
      column_exists?(:customer_supplier_commissions, :customer_fee_pct)
  end
end
