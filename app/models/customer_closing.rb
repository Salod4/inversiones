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

  def transfers_without_sale_for_closing
    Transfer.where(customer_id: customer_id, sale_id: nil)
            .where(to_entity_type: "Customer", to_entity_id: customer_id)
            .where(occurred_at: closing.business_date.all_day)
  end

  def totals
    s = sales_for_closing
    gross_total              = s.sum(:gross_deposit)
    provider_commission_total = s.sum(:provider_commission)
    seller_commission_total   = SalesUser.where(sale_id: s.ids).sum(:commission_amount)
    total_after_pcts          = gross_total - provider_commission_total - seller_commission_total
    transfer_applied_total    = s.sum(:total_transfer_applied)
    transfers_received_total  = transfers_without_sale_for_closing.sum(:amount)
    total_cliente             = total_after_pcts - transfer_applied_total - transfers_received_total

    {
      total_depositado: gross_total,
      total_despues_pcts: total_after_pcts,
      transferencias: transfer_applied_total,
      transferencias_recibidas: transfers_received_total,
      total_cliente: total_cliente
    }
  end
end
