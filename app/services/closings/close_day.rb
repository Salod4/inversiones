# app/services/closings/close_day.rb
module Closings
  class CloseDay
    include ActiveModel::Model

    attr_reader :business_date

    def initialize(business_date: Date.current)
      @business_date = business_date
    end

    def call
      ActiveRecord::Base.transaction do
        closing = Closing.lock.for_date(business_date).first_or_create!(
          business_date: business_date,
          status: "closed"
        )

        attach_sales!(closing)
        upsert_customer_aggregates!(closing)
        upsert_supplier_aggregates!(closing)
        update_totals!(closing)

        closing.update!(closed_at: Time.current)
        closing
      end
    end

    private

    def day_sales
      Sale.where(date: business_date, closing_id: nil)
    end

    def attach_sales!(closing)
      day_sales.update_all(closing_id: closing.id)
    end

    def upsert_customer_aggregates!(closing)
      # Agrupa por cliente usando las ventas YA adjuntas al closing
      per_customer = closing.sales.group(:customer_id).pluck(
        :customer_id,
        Arel.sql("COALESCE(SUM(customer_balance), 0)"),
        Arel.sql("COALESCE(SUM(customer_fee), 0)")
      )
      per_customer.each do |customer_id, balance_sum, receivables_sum|
        CustomerClosing
          .where(closing_id: closing.id, customer_id: customer_id)
          .first_or_initialize
          .update!(
            customer_balance: balance_sum,
            receivables: receivables_sum
          )
      end
    end

    def upsert_supplier_aggregates!(closing)
      # Ventas por proveedor (ya adjuntas al closing)
      per_supplier_sales = closing.sales.group(:supplier_id).pluck(
        :supplier_id,
        Arel.sql("COALESCE(SUM(provider_commission), 0)"),
        Arel.sql("COALESCE(SUM(total_transfer_applied), 0)")
      )

      # También puedes sumar transferencias del mismo día (si las consideras)
      per_supplier_transfers = Transfer.where(
        supplier_id: per_supplier_sales.map(&:first),
        occurred_at: business_date.beginning_of_day..business_date.end_of_day
      ).group(:supplier_id).sum(:amount)

      per_supplier_sales.each do |supplier_id, provider_commission_sum, total_transfer_applied_sum|
        transfers_sum = per_supplier_transfers[supplier_id] || 0

        SupplierClosing
          .where(closing_id: closing.id, supplier_id: supplier_id)
          .first_or_initialize
          .update!(
            supplier_credit: provider_commission_sum,
            amount_owed_to_supplier: transfers_sum # o total_transfer_applied_sum si lo prefieres
          )
      end
    end

    def update_totals!(closing)
      totals = closing.sales.pluck(
        Arel.sql("COALESCE(SUM(customer_balance), 0)"),
        Arel.sql("COALESCE(SUM(provider_commission), 0)")
      ).first

      total_customers = totals[0] || 0
      total_suppliers = totals[1] || 0

      closing.update!(
        total_customers: total_customers,
        total_suppliers: total_suppliers,
        difference: (total_customers.to_d - total_suppliers.to_d)
      )
    end
  end
end
