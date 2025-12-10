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
        snapshot = build_snapshot

        upsert_customer_aggregates!(closing, snapshot[:customers])
        upsert_supplier_aggregates!(closing, snapshot[:suppliers])
        update_totals!(closing, snapshot)

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

    def upsert_customer_aggregates!(closing, customers_snapshot)
      customers_snapshot.each do |customer_id, data|
        CustomerClosing
          .where(closing_id: closing.id, customer_id: customer_id)
          .first_or_initialize
          .update!(
            customer_balance: data[:balance],
            receivables: data[:receivables]
          )
      end
    end

    def upsert_supplier_aggregates!(closing, suppliers_snapshot)
      suppliers_snapshot.each do |supplier_id, data|
        SupplierClosing
          .where(closing_id: closing.id, supplier_id: supplier_id)
          .first_or_initialize
          .update!(
            supplier_credit: data[:ret_comp],
            amount_owed_to_supplier: data[:ret_comp] - data[:transferred]
          )
      end
    end

    def update_totals!(closing, snapshot)
      total_customers = snapshot[:customers].values.sum { |h| h[:balance].to_d }
      total_suppliers = snapshot[:suppliers].values.sum { |h| (h[:ret_comp] - h[:transferred]).to_d }

      closing.update!(
        total_customers: total_customers,
        total_suppliers: total_suppliers,
        difference: (total_customers.to_d - total_suppliers.to_d)
      )
    end

    def build_snapshot
      sales_scope = Sale.where("date <= ?", business_date).includes(:transfers)

      # Clientes: suma de working_capital menos transfers hasta la fecha
      customers = Hash.new { |h, k| h[k] = { balance: 0.to_d, receivables: 0.to_d } }
      sales_scope.find_each do |sale|
        transfers_sum = sale.transfers.where("occurred_at <= ?", business_date.end_of_day).sum(:amount).to_d
        balance = sale.working_capital.to_d - transfers_sum
        cust = customers[sale.customer_id]
        cust[:balance] += balance
        cust[:receivables] += sale.customer_fee.to_d
      end

      # Proveedores: RET.COMP (gross - provider_commission) menos transfers hasta la fecha
      suppliers = Hash.new { |h, k| h[k] = { ret_comp: 0.to_d, transferred: 0.to_d } }
      sales_scope.find_each do |sale|
        ret_comp = sale.gross_deposit.to_d - sale.provider_commission.to_d
        suppliers[sale.supplier_id][:ret_comp] += ret_comp
      end

      supplier_transfers = Transfer
                             .where("occurred_at <= ?", business_date.end_of_day)
                             .group(:supplier_id)
                             .sum(:amount)
      supplier_transfers.each do |supplier_id, amount|
        suppliers[supplier_id][:transferred] += amount.to_d
      end

      {
        customers: customers,
        suppliers: suppliers
      }
    end
  end
end
