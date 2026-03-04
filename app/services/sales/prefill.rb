# frozen_string_literal: true

require "bigdecimal/util"

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
      sale.provider_pct = pct.to_d
    end

    def preload_customer_fee_pct
      pct = resolved_customer_fee_pct
      sale.customer_fee_pct = pct.to_d
    end

    def preload_sales_users_splits
      sale.sales_users.target.clear
      vendor_defaults.order(:id).limit(Sale::MAX_SELLERS).find_each do |vd|
        pct = vd.commission_pct.to_d
        sale.sales_users.build(user: vd.user, user_id: vd.user_id, commission_pct: pct)
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

    def resolved_customer_fee_pct
      return sale.customer_fee_pct_override if sale.customer_fee_pct_override.present?

      default_fee = customer&.default_customer_fee_pct
      return default_fee if default_fee.present?

      link_fee = customer_supplier_link&.customer_fee_pct
      return link_fee if link_fee.present?

      sale.customer_fee_pct.presence || 0
    end

    def vendor_defaults
      return CustomerSupplierVendor.none unless customer_supplier_link
      CustomerSupplierVendor.where(customer_supplier_id: customer_supplier_link.id)
    end

    def skip_prefill?
      sale.persisted? || sale.sales_users.any?
    end
  end
end
