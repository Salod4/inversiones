class AddSupplierToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_reference :customers, :supplier, null: false, foreign_key: true
  end
end
