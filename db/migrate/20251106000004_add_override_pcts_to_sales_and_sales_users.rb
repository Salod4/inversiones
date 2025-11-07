# frozen_string_literal: true

class AddOverridePctsToSalesAndSalesUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :sales, :provider_pct_override,      :decimal, precision: 6, scale: 4
    add_column :sales, :customer_fee_pct_override,  :decimal, precision: 6, scale: 4
    add_column :sales_users, :commission_pct_override, :decimal, precision: 6, scale: 4

    execute <<~SQL
      ALTER TABLE sales
      ADD CONSTRAINT sales_provider_pct_override_range
      CHECK (provider_pct_override IS NULL OR (provider_pct_override >= 0 AND provider_pct_override < 1));
    SQL

    execute <<~SQL
      ALTER TABLE sales
      ADD CONSTRAINT sales_customer_fee_pct_override_range
      CHECK (customer_fee_pct_override IS NULL OR (customer_fee_pct_override >= 0 AND customer_fee_pct_override < 1));
    SQL

    execute <<~SQL
      ALTER TABLE sales_users
      ADD CONSTRAINT sales_users_commission_pct_override_range
      CHECK (commission_pct_override IS NULL OR (commission_pct_override >= 0 AND commission_pct_override < 1));
    SQL
  end
end
