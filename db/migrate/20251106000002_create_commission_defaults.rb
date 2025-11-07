# frozen_string_literal: true

class CreateCommissionDefaults < ActiveRecord::Migration[8.0]
  def change
    create_table :commission_defaults do |t|
      t.references :supplier, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.references :user,     null: false, foreign_key: true
      t.decimal :commission_pct, precision: 6, scale: 4, null: false, default: 0

      t.timestamps
    end

    add_index :commission_defaults,
              [ :supplier_id, :customer_id, :user_id ],
              unique: true,
              name: "idx_commission_defaults_unique"

    execute <<~SQL
      ALTER TABLE commission_defaults
      ADD CONSTRAINT commission_defaults_pct_range
      CHECK (commission_pct >= 0 AND commission_pct < 1);
    SQL
  end
end
