# frozen_string_literal: true

class CreateCustomerSupplierVendors < ActiveRecord::Migration[8.0]
  def up
    create_table :customer_supplier_vendors do |t|
      t.references :customer_supplier, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.decimal :commission_pct, precision: 6, scale: 4, null: false, default: 0

      t.timestamps
    end

    add_index :customer_supplier_vendors,
              [ :customer_supplier_id, :user_id ],
              unique: true,
              name: "idx_customer_supplier_vendors_unique"

    execute <<~SQL
      ALTER TABLE customer_supplier_vendors
      ADD CONSTRAINT customer_supplier_vendors_pct_range
      CHECK (commission_pct >= 0 AND commission_pct < 1);
    SQL

    backfill_customer_supplier_vendors!
  end

  def down
    drop_table :customer_supplier_vendors
  end

  private

  def backfill_customer_supplier_vendors!
    say_with_time "Backfilling customer_supplier_vendors from commission_defaults" do
      commission_defaults = Class.new(ActiveRecord::Base) { self.table_name = "commission_defaults" }
      customer_suppliers = Class.new(ActiveRecord::Base) { self.table_name = "customer_suppliers" }
      customer_supplier_vendors = Class.new(ActiveRecord::Base) { self.table_name = "customer_supplier_vendors" }

      commission_defaults.find_each do |cd|
        cs = customer_suppliers.find_or_create_by!(
          customer_id: cd.customer_id,
          supplier_id: cd.supplier_id
        )

        record = customer_supplier_vendors.find_or_initialize_by(
          customer_supplier_id: cs.id,
          user_id: cd.user_id
        )
        record.commission_pct = cd.commission_pct
        record.save!
      end
    end
  end
end
