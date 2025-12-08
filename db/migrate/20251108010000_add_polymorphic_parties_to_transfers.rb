# frozen_string_literal: true

class AddPolymorphicPartiesToTransfers < ActiveRecord::Migration[8.0]
  def up
    add_column :transfers, :from_entity_type, :string
    add_column :transfers, :from_entity_id, :bigint
    add_column :transfers, :to_entity_type, :string
    add_column :transfers, :to_entity_id, :bigint

    change_column_null :transfers, :customer_id, true
    change_column_null :transfers, :supplier_id, true

    execute <<~SQL.squish
      UPDATE transfers t
      SET from_entity_type = 'Customer',
          from_entity_id   = t.customer_id,
          to_entity_type   = 'Supplier',
          to_entity_id     = t.supplier_id
      WHERE t.sale_id IS NOT NULL OR t.customer_id IS NOT NULL OR t.supplier_id IS NOT NULL
    SQL

    change_column_null :transfers, :from_entity_type, false
    change_column_null :transfers, :from_entity_id, false
    change_column_null :transfers, :to_entity_type, false
    change_column_null :transfers, :to_entity_id, false

    add_index :transfers, [ :from_entity_type, :from_entity_id ], name: "index_transfers_on_from_entity"
    add_index :transfers, [ :to_entity_type, :to_entity_id ], name: "index_transfers_on_to_entity"
  end

  def down
    remove_index :transfers, name: "index_transfers_on_from_entity"
    remove_index :transfers, name: "index_transfers_on_to_entity"

    remove_column :transfers, :from_entity_type
    remove_column :transfers, :from_entity_id
    remove_column :transfers, :to_entity_type
    remove_column :transfers, :to_entity_id

    change_column_null :transfers, :customer_id, false
    change_column_null :transfers, :supplier_id, false
  end
end
