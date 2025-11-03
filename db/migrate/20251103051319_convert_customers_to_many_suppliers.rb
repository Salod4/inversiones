class ConvertCustomersToManySuppliers < ActiveRecord::Migration[8.0]
 def up
    create_table :customer_suppliers do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true
      t.timestamps
    end
    add_index :customer_suppliers, [ :customer_id, :supplier_id ], unique: true

    # Si ya existe la FK vieja, migra datos y bórrala
    if column_exists?(:customers, :supplier_id)
      execute <<~SQL
        INSERT INTO customer_suppliers (customer_id, supplier_id, created_at, updated_at)
        SELECT id, supplier_id, NOW(), NOW()
        FROM customers
        WHERE supplier_id IS NOT NULL
        ON CONFLICT (customer_id, supplier_id) DO NOTHING;
      SQL

      remove_reference :customers, :supplier, foreign_key: true
    end
  end

  def down
    # Reponer la FK (opcionalmente nullable para no romper)
    unless column_exists?(:customers, :supplier_id)
      add_reference :customers, :supplier, null: true, foreign_key: true
    end

    # Volcar un proveedor por customer (el más antiguo enlazado)
    execute <<~SQL
      UPDATE customers SET supplier_id = cs.supplier_id
      FROM (
        SELECT DISTINCT ON (customer_id) customer_id, supplier_id
        FROM customer_suppliers
        ORDER BY customer_id, created_at ASC
      ) cs
      WHERE customers.id = cs.customer_id;
    SQL

    drop_table :customer_suppliers
  end
end
