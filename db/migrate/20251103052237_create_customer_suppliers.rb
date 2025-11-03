class CreateCustomerSuppliers < ActiveRecord::Migration[8.0]
  def change
    create_table :customer_suppliers do |t|
      t.references :customer_id, null: false, foreign_key: true
      t.references :supplier_id, null: false, foreign_key: true

      t.timestamps
    end
  end
end
