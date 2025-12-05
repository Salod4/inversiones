# frozen_string_literal: true

class AddCustomerToTransfers < ActiveRecord::Migration[8.0]
  def up
    add_reference :transfers, :customer, foreign_key: true

    execute <<~SQL.squish
      UPDATE transfers t
      SET customer_id = s.customer_id
      FROM sales s
      WHERE t.sale_id = s.id
    SQL

    remaining = select_value("SELECT COUNT(*) FROM transfers WHERE customer_id IS NULL").to_i
    if remaining.positive?
      raise ActiveRecord::IrreversibleMigration, "No se pudo poblar customer_id para #{remaining} transfers"
    end

    change_column_null :transfers, :customer_id, false
  end

  def down
    remove_reference :transfers, :customer, foreign_key: true
  end
end
