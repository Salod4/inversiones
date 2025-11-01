class CreateClosings < ActiveRecord::Migration[8.0]
  def change
create_table :closings, if_not_exists: true do |t|
  t.date     :business_date, null: false
  t.datetime :closed_at
  t.string   :status, null: false, default: "closed"
  t.decimal  :total_customers, precision: 15, scale: 2
  t.decimal  :total_suppliers, precision: 15, scale: 2
  t.decimal  :difference,      precision: 15, scale: 2
  t.timestamps
end
add_index :closings, :business_date, unique: true unless index_exists?(:closings, :business_date)
end
end
