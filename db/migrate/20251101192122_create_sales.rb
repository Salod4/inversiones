class CreateSales < ActiveRecord::Migration[8.0]
  def change
create_table :sales, if_not_exists: true do |t|
  t.string :code
  t.date   :date
  t.references :customer, null: false, foreign_key: true
  t.references :supplier, null: false, foreign_key: true
  t.references :closing,  null: true,  foreign_key: true
  t.decimal :gross_deposit, precision: 15, scale: 2
  t.decimal :net_base,      precision: 15, scale: 2
  t.decimal :provider_pct,  precision: 6,  scale: 4, null: false, default: 0.0
  t.decimal :customer_fee_pct, precision: 6, scale: 4
  t.decimal :provider_commission, precision: 15, scale: 2
  t.decimal :customer_fee,        precision: 15, scale: 2
  t.decimal :total_transfer_applied, precision: 15, scale: 2, null: false, default: 0.0
  t.decimal :working_capital,   precision: 15, scale: 2
  t.decimal :customer_balance,  precision: 15, scale: 2
  t.string  :status, null: false, default: "open"
  t.timestamps
end
add_index :sales, :code, unique: true unless index_exists?(:sales, :code)
add_index :sales, :customer_id    unless index_exists?(:sales, :customer_id)
add_index :sales, :supplier_id    unless index_exists?(:sales, :supplier_id)
add_index :sales, :closing_id     unless index_exists?(:sales, :closing_id)
end
end
