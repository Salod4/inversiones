class AddFromOtherNameToTransfers < ActiveRecord::Migration[8.0]
  def change
    add_column :transfers, :from_other_name, :string
  end
end
