# frozen_string_literal: true

class AlignForeignKeysToBigint < ActiveRecord::Migration[8.0]
  def up
    change_fk(:customer_closings, :closing_id, :closings, :bigint)
    change_fk(:customer_closings, :customer_id, :customers, :bigint)

    change_fk(:sales, :customer_id, :customers, :bigint)
    change_fk(:sales, :supplier_id, :suppliers, :bigint)
    change_fk(:sales, :closing_id, :closings, :bigint)

    change_fk(:sales_users, :sale_id, :sales, :bigint)
    change_fk(:sales_users, :user_id, :users, :bigint)

    change_fk(:supplier_closings, :closing_id, :closings, :bigint)
    change_fk(:supplier_closings, :supplier_id, :suppliers, :bigint)

    change_fk(:transfers, :sale_id, :sales, :bigint)
    change_fk(:transfers, :supplier_id, :suppliers, :bigint)
  end

  def down
    change_fk(:customer_closings, :closing_id, :closings, :integer)
    change_fk(:customer_closings, :customer_id, :customers, :integer)

    change_fk(:sales, :customer_id, :customers, :integer)
    change_fk(:sales, :supplier_id, :suppliers, :integer)
    change_fk(:sales, :closing_id, :closings, :integer)

    change_fk(:sales_users, :sale_id, :sales, :integer)
    change_fk(:sales_users, :user_id, :users, :integer)

    change_fk(:supplier_closings, :closing_id, :closings, :integer)
    change_fk(:supplier_closings, :supplier_id, :suppliers, :integer)

    change_fk(:transfers, :sale_id, :sales, :integer)
    change_fk(:transfers, :supplier_id, :suppliers, :integer)
  end

  private

  def change_fk(table, column, referenced_table, type)
    fk_exists = foreign_key_exists?(table, column: column)
    remove_foreign_key(table, column: column) if fk_exists

    change_column table, column, type, using: "#{column}::#{type}"

    add_foreign_key(table, referenced_table, column: column) if fk_exists
  end
end
