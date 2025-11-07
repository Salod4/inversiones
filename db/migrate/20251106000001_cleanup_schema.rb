# frozen_string_literal: true

class CleanupSchema < ActiveRecord::Migration[8.0]
  def up
    # 1) Índice duplicado en customer_suppliers
    if index_exists?(:customer_suppliers, %i[customer_id supplier_id], name: "index_customer_suppliers_on_customer_and_supplier")
      remove_index :customer_suppliers, name: "index_customer_suppliers_on_customer_and_supplier"
    end

    # Normalizamos datos previos a los NOT NULL para evitar fallos
    execute <<~SQL
      UPDATE customers
      SET code = 'TMP-CUST-' || id
      WHERE code IS NULL;
    SQL

    execute <<~SQL
      UPDATE customers
      SET name = 'TMP Customer ' || id
      WHERE name IS NULL;
    SQL

    execute <<~SQL
      UPDATE suppliers
      SET code = 'TMP-SUP-' || id
      WHERE code IS NULL;
    SQL

    execute <<~SQL
      UPDATE suppliers
      SET name = 'TMP Supplier ' || id
      WHERE name IS NULL;
    SQL

    execute <<~SQL
      UPDATE sales
      SET code = 'TMP-SALE-' || id
      WHERE code IS NULL;
    SQL

    execute <<~SQL
      UPDATE sales
      SET date = COALESCE(date, created_at::date, CURRENT_DATE)
      WHERE date IS NULL;
    SQL

    execute <<~SQL
      UPDATE transfers
      SET code = 'TMP-TRF-' || id
      WHERE code IS NULL;
    SQL

    execute <<~SQL
      UPDATE transfers
      SET occurred_at = COALESCE(occurred_at, created_at, NOW())
      WHERE occurred_at IS NULL;
    SQL

    execute <<~SQL
      UPDATE suppliers
      SET default_analysis_pct = 0
      WHERE default_analysis_pct < 0 OR default_analysis_pct >= 1;
    SQL

    execute <<~SQL
      UPDATE sales
      SET provider_pct = 0
      WHERE provider_pct < 0 OR provider_pct >= 1;
    SQL

    execute <<~SQL
      UPDATE sales
      SET customer_fee_pct = NULL
      WHERE customer_fee_pct < 0 OR customer_fee_pct >= 1;
    SQL

    execute <<~SQL
      UPDATE sales_users
      SET commission_pct = 0
      WHERE commission_pct < 0 OR commission_pct >= 1;
    SQL

    execute <<~SQL
      UPDATE sales
      SET gross_deposit = 0
      WHERE gross_deposit < 0;
    SQL

    execute <<~SQL
      UPDATE sales
      SET net_base = 0
      WHERE net_base < 0;
    SQL

    execute <<~SQL
      UPDATE sales
      SET provider_commission = 0
      WHERE provider_commission < 0;
    SQL

    execute <<~SQL
      UPDATE sales
      SET customer_fee = 0
      WHERE customer_fee < 0;
    SQL

    execute <<~SQL
      UPDATE sales
      SET total_transfer_applied = 0
      WHERE total_transfer_applied < 0;
    SQL

    execute <<~SQL
      UPDATE sales
      SET working_capital = 0
      WHERE working_capital < 0;
    SQL

    execute <<~SQL
      UPDATE sales
      SET customer_balance = 0
      WHERE customer_balance < 0;
    SQL

    execute <<~SQL
      UPDATE transfers
      SET amount = 0
      WHERE amount < 0;
    SQL

    # 2) NOT NULL en claves básicas
    change_column_null :customers, :code, false
    change_column_null :customers, :name, false
    change_column_null :suppliers, :code, false
    change_column_null :suppliers, :name, false
    change_column_null :sales,     :code, false
    change_column_null :sales,     :date, false
    change_column_null :transfers, :code, false
    change_column_null :transfers, :occurred_at, false

    # 3) CHECKs de rangos para % y no-negativos para montos
    execute <<~SQL
      ALTER TABLE suppliers
      ADD CONSTRAINT suppliers_default_analysis_pct_range
      CHECK (default_analysis_pct >= 0 AND default_analysis_pct < 1);
    SQL

    execute <<~SQL
      ALTER TABLE sales
      ADD CONSTRAINT sales_provider_pct_range
      CHECK (provider_pct >= 0 AND provider_pct < 1);
    SQL

    execute <<~SQL
      ALTER TABLE sales
      ADD CONSTRAINT sales_customer_fee_pct_range
      CHECK (customer_fee_pct >= 0 AND customer_fee_pct < 1);
    SQL

    execute <<~SQL
      ALTER TABLE sales_users
      ADD CONSTRAINT sales_users_commission_pct_range
      CHECK (commission_pct >= 0 AND commission_pct < 1);
    SQL

    execute <<~SQL
      ALTER TABLE sales
      ADD CONSTRAINT sales_money_nonnegative
      CHECK (
        (gross_deposit IS NULL OR gross_deposit >= 0) AND
        (net_base IS NULL OR net_base >= 0) AND
        (provider_commission IS NULL OR provider_commission >= 0) AND
        (customer_fee IS NULL OR customer_fee >= 0) AND
        (total_transfer_applied IS NULL OR total_transfer_applied >= 0) AND
        (working_capital IS NULL OR working_capital >= 0) AND
        (customer_balance IS NULL OR customer_balance >= 0)
      );
    SQL

    execute <<~SQL
      ALTER TABLE transfers
      ADD CONSTRAINT transfers_amount_nonnegative
      CHECK (amount >= 0);
    SQL
  end

  def down
    execute "ALTER TABLE transfers DROP CONSTRAINT IF EXISTS transfers_amount_nonnegative;"
    execute "ALTER TABLE sales DROP CONSTRAINT IF EXISTS sales_money_nonnegative;"
    execute "ALTER TABLE sales DROP CONSTRAINT IF EXISTS sales_customer_fee_pct_range;"
    execute "ALTER TABLE sales DROP CONSTRAINT IF EXISTS sales_provider_pct_range;"
    execute "ALTER TABLE sales_users DROP CONSTRAINT IF EXISTS sales_users_commission_pct_range;"
    execute "ALTER TABLE suppliers DROP CONSTRAINT IF EXISTS suppliers_default_analysis_pct_range;"

    change_column_null :transfers, :occurred_at, true
    change_column_null :transfers, :code, true
    change_column_null :sales,     :date, true
    change_column_null :sales,     :code, true
    change_column_null :suppliers, :name, true
    change_column_null :suppliers, :code, true
    change_column_null :customers, :name, true
    change_column_null :customers, :code, true
  end
end
