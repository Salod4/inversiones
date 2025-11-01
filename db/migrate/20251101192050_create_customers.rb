class CreateCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :customers, if_not_exists: true do |t|
  t.string :code
  t.string :name
  t.decimal :default_customer_fee_pct, precision: 6, scale: 4
  t.timestamps
end
add_index :customers, :code, unique: true unless index_exists?(:customers, :code)
end
end
