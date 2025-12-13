class CreateOpeningBalances < ActiveRecord::Migration[7.1]
  def change
    create_table :opening_balances do |t|
      t.string :reference_type, null: false
      t.bigint :reference_id
      t.string :group_name
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.string :source
      t.timestamps
    end

    add_index :opening_balances, [ :reference_type, :reference_id ]
    add_index :opening_balances, :group_name
  end
end
