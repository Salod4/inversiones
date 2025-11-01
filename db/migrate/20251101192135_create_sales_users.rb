class CreateSalesUsers < ActiveRecord::Migration[8.0]
  def change
create_table :sales_users, if_not_exists: true do |t|
  t.references :sale, null: false, foreign_key: true
  t.references :user, null: false, foreign_key: true
  t.decimal :commission_pct,    precision: 6,  scale: 4, null: false, default: 0.0
  t.decimal :commission_amount, precision: 15, scale: 2
  t.timestamps
end
add_index :sales_users, :sale_id unless index_exists?(:sales_users, :sale_id)
add_index :sales_users, :user_id unless index_exists?(:sales_users, :user_id)
end
end
