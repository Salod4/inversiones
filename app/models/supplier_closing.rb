class SupplierClosing < ApplicationRecord
  belongs_to :closing
  belongs_to :supplier

  validates :supplier_credit, numericality: true, allow_nil: true
  validates :amount_owed_to_supplier, numericality: true, allow_nil: true

  def sales_for_closing
    Sale.for_supplier_closing(self)
        .includes(:customer)
        .order(:date, :code)
  end

  # Transfers of this supplier on the closing's business_date
  def transfers_for_closing
    Transfer.where(supplier_id: supplier_id)
            .where(occurred_at: closing.business_date.all_day)
            .includes(:sale, :customer)
            .order(:occurred_at, :code)
  end

  def totals
    s = sales_for_closing
    t = transfers_for_closing

    {
      gross_deposit:          s.sum(:gross_deposit),
      net_base:               s.sum(:net_base),
      provider_commission:    s.sum(:provider_commission),
      total_transfer_applied: s.sum(:total_transfer_applied),
      transfer_count:         t.count,
      transfer_amount:        t.sum(:amount),
      supplier_credit_at_closing:            supplier_credit,
      amount_owed_to_supplier_at_closing:    amount_owed_to_supplier
    }
  end
end
