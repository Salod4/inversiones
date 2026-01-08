class AddCashBoxAmountToTransfers < ActiveRecord::Migration[7.1]
  def change
    add_column :transfers, :cash_box_amount, :decimal, precision: 15, scale: 2, default: 0, null: false
    add_check_constraint :transfers, "cash_box_amount >= 0", name: "transfers_cash_box_nonnegative"
  end
end
