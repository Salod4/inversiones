class CreateCustomerClosings < ActiveRecord::Migration[8.0]
  def change
   create_table :customer_closings, if_not_exists: true do |t|
  t.references :closing,  null: false, foreign_key: true
  t.references :customer, null: false, foreign_key: true
  t.decimal :customer_balance, precision: 15, scale: 2
  t.decimal :receivables,      precision: 15, scale: 2
  t.timestamps
end
add_index :customer_closings, :closing_id  unless index_exists?(:customer_closings, :closing_id)
add_index :customer_closings, :customer_id unless index_exists?(:customer_closings, :customer_id)
end
end
