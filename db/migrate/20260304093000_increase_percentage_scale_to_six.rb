class IncreasePercentageScaleToSix < ActiveRecord::Migration[8.0]
  def up
    change_column :commission_defaults, :commission_pct, :decimal, precision: 8, scale: 6, default: 0, null: false
    change_column :customer_supplier_vendors, :commission_pct, :decimal, precision: 8, scale: 6, default: 0, null: false
    change_column :customer_suppliers, :customer_fee_pct, :decimal, precision: 8, scale: 6
    change_column :customers, :default_customer_fee_pct, :decimal, precision: 8, scale: 6
    change_column :sales, :provider_pct, :decimal, precision: 8, scale: 6, default: 0, null: false
    change_column :sales, :customer_fee_pct, :decimal, precision: 8, scale: 6, default: 0
    change_column :sales, :provider_pct_override, :decimal, precision: 8, scale: 6
    change_column :sales, :customer_fee_pct_override, :decimal, precision: 8, scale: 6
    change_column :sales_users, :commission_pct, :decimal, precision: 8, scale: 6, default: 0, null: false
    change_column :sales_users, :commission_pct_override, :decimal, precision: 8, scale: 6
    change_column :suppliers, :default_analysis_pct, :decimal, precision: 8, scale: 6, default: 0, null: false
  end

  def down
    change_column :commission_defaults, :commission_pct, :decimal, precision: 6, scale: 4, default: 0, null: false
    change_column :customer_supplier_vendors, :commission_pct, :decimal, precision: 6, scale: 4, default: 0, null: false
    change_column :customer_suppliers, :customer_fee_pct, :decimal, precision: 6, scale: 4
    change_column :customers, :default_customer_fee_pct, :decimal, precision: 6, scale: 4
    change_column :sales, :provider_pct, :decimal, precision: 6, scale: 4, default: 0, null: false
    change_column :sales, :customer_fee_pct, :decimal, precision: 6, scale: 4, default: 0
    change_column :sales, :provider_pct_override, :decimal, precision: 6, scale: 4
    change_column :sales, :customer_fee_pct_override, :decimal, precision: 6, scale: 4
    change_column :sales_users, :commission_pct, :decimal, precision: 6, scale: 4, default: 0, null: false
    change_column :sales_users, :commission_pct_override, :decimal, precision: 6, scale: 4
    change_column :suppliers, :default_analysis_pct, :decimal, precision: 6, scale: 4, default: 0, null: false
  end
end
