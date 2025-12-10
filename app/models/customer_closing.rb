class CustomerClosing < ApplicationRecord
  belongs_to :closing
  belongs_to :customer

  validates :customer_balance, numericality: true, allow_nil: true
  validates :receivables, numericality: true, allow_nil: true

  def sales_for_closing
    Sale.for_customer_closing(self)
        .includes(:supplier)
        .order(:date, :code)
  end

  def totals
    s = sales_for_closing

    {
      gross_deposit:          s.sum(:gross_deposit),
      net_base:               s.sum(:net_base),
      provider_commission:    s.sum(:provider_commission),
      customer_fee:           s.sum(:customer_fee),
      total_transfer_applied: s.sum(:total_transfer_applied),
      working_capital:        s.sum(:working_capital),
      customer_balance:       s.sum(:customer_balance),
      customer_balance_at_closing: customer_balance,
      receivables_at_closing:      receivables
    }
  end
end
