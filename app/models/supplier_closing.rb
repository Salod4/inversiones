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
    gross_total = s.sum(:gross_deposit)
    provider_commission_total = s.sum(:provider_commission)
    ret_comp_total = gross_total - provider_commission_total
    transfer_amount = t.sum(:amount)
    saldo_pendiente = ret_comp_total - transfer_amount

    {
      analisis_base_pct: supplier&.default_analysis_pct,
      total_asignado: gross_total,
      ret_comp_total: ret_comp_total,
      transferido: transfer_amount,
      saldo_pendiente: saldo_pendiente
    }
  end
end
