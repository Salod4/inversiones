class AddCustomerGroupToTransfers < ActiveRecord::Migration[8.0]
  def change
    change_column_null :transfers, :from_entity_id, true
    change_column_null :transfers, :to_entity_id, true

    add_column :transfers, :from_group, :string
    add_column :transfers, :to_group, :string
  end
end
