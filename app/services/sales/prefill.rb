# frozen_string_literal: true

module Sales
  class Prefill
    def self.call(sale)
      new(sale).call
    end

    def initialize(sale)
      @sale = sale
    end

    def call
      return sale if skip_prefill?
      preload_provider_pct
      preload_customer_fee_pct
      preload_sales_users_splits
      sale
    end

  private

    attr_reader :sale

    def preload_provider_pct
      pct = sale.provider_pct_override.presence ||
            supplier&.default_analysis_pct ||
            0
      sale.provider_pct = pct.to_f
    end

    def preload_customer_fee_pct
      pct = sale.customer_fee_pct_override.presence ||
            customer_supplier_link&.customer_fee_pct ||
            customer&.default_customer_fee_pct ||
            0
      sale.customer_fee_pct = pct.to_f
    end

    def preload_sales_users_splits
      sale.sales_users.target.clear
      commission_defaults.order(:id).limit(Sale::MAX_SELLERS).find_each do |cd|
        pct = cd.commission_pct.to_f
        sale.sales_users.build(user: cd.user, user_id: cd.user_id, commission_pct: pct)
      end
    end

    def supplier
      @supplier ||= sale.supplier || Supplier.find_by(id: sale.supplier_id)
    end

    def customer
      @customer ||= sale.customer || Customer.find_by(id: sale.customer_id)
    end

    def customer_supplier_link
      return unless sale.customer_id.present? && sale.supplier_id.present?
      @customer_supplier_link ||= CustomerSupplier.find_by(
        customer_id: sale.customer_id,
        supplier_id: sale.supplier_id
      )
    end

    def commission_defaults
      return CommissionDefault.none unless sale.supplier_id.present? && sale.customer_id.present?
      CommissionDefault.where(supplier_id: sale.supplier_id, customer_id: sale.customer_id)
    end

    def skip_prefill?
      sale.persisted? || sale.sales_users.any?
    end
  end
end
