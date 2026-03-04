# frozen_string_literal: true

require "bigdecimal/util"

module Sales
  class SnapshotPcts
    def self.call(sale)
      new(sale).call
    end

    def initialize(sale)
      @sale = sale
    end

    def call
      snapshot_provider_pct!
      snapshot_customer_fee_pct!
      snapshot_sales_users_splits!
      compute_net_base!
      compute_amounts!
      sale
    end

    private

    attr_reader :sale

    def snapshot_provider_pct!
      pct = sale.provider_pct_override.presence ||
            supplier&.default_analysis_pct ||
            0
      sale.provider_pct = pct.to_d
    end

    def snapshot_customer_fee_pct!
      pct = resolved_customer_fee_pct
      sale.customer_fee_pct = pct.to_d
    end

    def snapshot_sales_users_splits!
      vendor_defaults.find_each do |vd|
        su = find_or_build_sales_user(vd.user_id)
        pct = su.commission_pct_override.presence || vd.commission_pct || 0
        su.commission_pct = pct.to_d
      end
    end

    def find_or_build_sales_user(user_id)
      sale.sales_users.detect { |su| su.user_id.to_i == user_id.to_i } || sale.sales_users.build(user_id: user_id)
    end

    def compute_net_base!
      sale.net_base = (sale.gross_deposit.to_d / BigDecimal("1.16")).round(2)
    end

    def compute_amounts!
      nb = sale.net_base.to_d
      sale.provider_commission = (nb * sale.provider_pct.to_d).round(2)
      sale.customer_fee        = (nb * sale.customer_fee_pct.to_d).round(2)
      sale.sales_users.each do |su|
        pct = su.commission_pct_override.presence || su.commission_pct
        su.commission_amount = (nb * pct.to_d).round(2)
      end

      sale.working_capital = (sale.gross_deposit.to_d - sale.customer_fee.to_d).round(2)

      transfer_total        = sale.transfers.sum(:amount).to_d
      sale.customer_balance = (sale.working_capital.to_d - transfer_total).round(2)
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
  end
end
