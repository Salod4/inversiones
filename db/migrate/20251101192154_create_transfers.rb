class CreateTransfers < ActiveRecord::Migration[8.0]
  def change
    create_table :transfers, if_not_exists: true do |t|
  t.string   :code
  t.datetime :occurred_at
  t.references :sale,     null: false, foreign_key: true
  t.references :supplier, null: false, foreign_key: true
  t.decimal  :amount, precision: 15, scale: 2, null: false
  t.text     :note
  t.timestamps
end
add_index :transfers, :code, unique: true unless index_exists?(:transfers, :code)
add_index :transfers, :sale_id     unless index_exists?(:transfers, :sale_id)
add_index :transfers, :supplier_id unless index_exists?(:transfers, :supplier_id)
end
end
