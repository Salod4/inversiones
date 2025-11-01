class TuneMoneyAndPctDefaults < ActiveRecord::Migration[8.0]
  def change
    change_column_default :sales, :customer_fee_pct, from: nil, to: 0
    change_column_default :sales, :provider_commission, from: nil, to: 0
    change_column_default :sales, :customer_fee, from: nil, to: 0
    change_column_default :sales, :working_capital, from: nil, to: 0
    change_column_default :sales, :customer_balance, from: nil, to: 0

    change_column_default :sales_users, :commission_amount, from: nil, to: 0
  end
end
