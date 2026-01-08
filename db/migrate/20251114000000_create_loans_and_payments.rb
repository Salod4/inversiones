class CreateLoansAndPayments < ActiveRecord::Migration[7.1]
  def change
    create_table :loans do |t|
      t.string :name, null: false
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.decimal :total_paid, precision: 15, scale: 2, null: false, default: 0
      t.datetime :last_payment_at
      t.text :note

      t.timestamps
    end

    create_table :loan_payments do |t|
      t.references :loan, null: false, foreign_key: true
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.datetime :paid_at

      t.timestamps
    end

    add_index :loan_payments, :paid_at
  end
end
