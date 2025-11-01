class CreateSuppliers < ActiveRecord::Migration[8.0]
  def change
    create_table :suppliers, if_not_exists: true do |t|
      t.string  :code
      t.string  :name
      t.decimal :default_analysis_pct, precision: 6, scale: 4, null: false, default: 0
      t.timestamps
    end

    add_index :suppliers, :code, unique: true unless index_exists?(:suppliers, :code)
  end
end
