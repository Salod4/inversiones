class CreateSupplierClosings < ActiveRecord::Migration[8.0]
  def change
create_table :supplier_closings, if_not_exists: true do |t|
  t.references :closing,  null: false, foreign_key: true
  t.references :supplier, null: false, foreign_key: true
  t.decimal :supplier_credit,         precision: 15, scale: 2
  t.decimal :amount_owed_to_supplier, precision: 15, scale: 2
  t.timestamps
end
add_index :supplier_closings, :closing_id  unless index_exists?(:supplier_closings, :closing_id)
add_index :supplier_closings, :supplier_id unless index_exists?(:supplier_closings, :supplier_id)

  end
end
