class CreateCustomerSuppliers < ActiveRecord::Migration[8.0]
  def change
    create_table :customer_suppliers, if_not_exists: true do |t|
      # Ajusta las columnas a lo que necesitas:
      t.references :customer, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true
      t.timestamps
    end

    # Evita re-crear índices si ya existen
    add_index :customer_suppliers, [ :customer_id, :supplier_id ],
              unique: true,
              name: "index_customer_suppliers_on_customer_and_supplier",
              if_not_exists: true
  end
end
