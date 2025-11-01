# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_11_01_192245) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "closings", force: :cascade do |t|
    t.date "business_date", null: false
    t.datetime "closed_at"
    t.string "status", default: "closed", null: false
    t.decimal "total_customers", precision: 15, scale: 2
    t.decimal "total_suppliers", precision: 15, scale: 2
    t.decimal "difference", precision: 15, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_date"], name: "index_closings_on_business_date", unique: true
  end

  create_table "customer_closings", force: :cascade do |t|
    t.integer "closing_id", null: false
    t.integer "customer_id", null: false
    t.decimal "customer_balance", precision: 15, scale: 2
    t.decimal "receivables", precision: 15, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["closing_id"], name: "index_customer_closings_on_closing_id"
    t.index ["customer_id"], name: "index_customer_closings_on_customer_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.decimal "default_customer_fee_pct", precision: 6, scale: 4
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_customers_on_code", unique: true
  end

  create_table "sales", force: :cascade do |t|
    t.string "code"
    t.date "date"
    t.integer "customer_id", null: false
    t.integer "supplier_id", null: false
    t.integer "closing_id"
    t.decimal "gross_deposit", precision: 15, scale: 2
    t.decimal "net_base", precision: 15, scale: 2
    t.decimal "provider_pct", precision: 6, scale: 4, default: "0.0", null: false
    t.decimal "customer_fee_pct", precision: 6, scale: 4, default: "0.0"
    t.decimal "provider_commission", precision: 15, scale: 2, default: "0.0"
    t.decimal "customer_fee", precision: 15, scale: 2, default: "0.0"
    t.decimal "total_transfer_applied", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "working_capital", precision: 15, scale: 2, default: "0.0"
    t.decimal "customer_balance", precision: 15, scale: 2, default: "0.0"
    t.string "status", default: "open", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["closing_id"], name: "index_sales_on_closing_id"
    t.index ["code"], name: "index_sales_on_code", unique: true
    t.index ["customer_id"], name: "index_sales_on_customer_id"
    t.index ["supplier_id"], name: "index_sales_on_supplier_id"
  end

  create_table "sales_users", force: :cascade do |t|
    t.integer "sale_id", null: false
    t.integer "user_id", null: false
    t.decimal "commission_pct", precision: 6, scale: 4, default: "0.0", null: false
    t.decimal "commission_amount", precision: 15, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sale_id"], name: "index_sales_users_on_sale_id"
    t.index ["user_id"], name: "index_sales_users_on_user_id"
  end

  create_table "supplier_closings", force: :cascade do |t|
    t.integer "closing_id", null: false
    t.integer "supplier_id", null: false
    t.decimal "supplier_credit", precision: 15, scale: 2
    t.decimal "amount_owed_to_supplier", precision: 15, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["closing_id"], name: "index_supplier_closings_on_closing_id"
    t.index ["supplier_id"], name: "index_supplier_closings_on_supplier_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.decimal "default_analysis_pct", precision: 6, scale: 4, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_suppliers_on_code", unique: true
  end

  create_table "transfers", force: :cascade do |t|
    t.string "code"
    t.datetime "occurred_at"
    t.integer "sale_id", null: false
    t.integer "supplier_id", null: false
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_transfers_on_code", unique: true
    t.index ["sale_id"], name: "index_transfers_on_sale_id"
    t.index ["supplier_id"], name: "index_transfers_on_supplier_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "customer_closings", "closings"
  add_foreign_key "customer_closings", "customers"
  add_foreign_key "sales", "closings"
  add_foreign_key "sales", "customers"
  add_foreign_key "sales", "suppliers"
  add_foreign_key "sales_users", "sales"
  add_foreign_key "sales_users", "users"
  add_foreign_key "supplier_closings", "closings"
  add_foreign_key "supplier_closings", "suppliers"
  add_foreign_key "transfers", "sales"
  add_foreign_key "transfers", "suppliers"
end
