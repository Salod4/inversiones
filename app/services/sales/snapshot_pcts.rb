# frozen_string_literal: true

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
      sale.provider_pct = pct.to_f
    end

    def snapshot_customer_fee_pct!
      pct = sale.customer_fee_pct_override.presence ||
            customer_supplier_link&.customer_fee_pct ||
            customer&.default_customer_fee_pct ||
            0
      sale.customer_fee_pct = pct.to_f
    end

    def snapshot_sales_users_splits!
      commission_defaults.find_each do |cd|
        su = find_or_build_sales_user(cd.user_id)
        pct = su.commission_pct_override.presence || cd.commission_pct || 0
        su.commission_pct = pct.to_f
      end
    end

    def find_or_build_sales_user(user_id)
      sale.sales_users.detect { |su| su.user_id.to_i == user_id.to_i } || sale.sales_users.build(user_id: user_id)
    end

    def compute_net_base!
      sale.net_base = (sale.gross_deposit.to_f / 1.16).round(2)
    end

    def compute_amounts!
      nb = sale.net_base.to_f
      sale.provider_commission = (nb * sale.provider_pct.to_f).round(2)
      sale.customer_fee        = (nb * sale.customer_fee_pct.to_f).round(2)
      sale.working_capital     = (nb - sale.provider_commission.to_f - sale.customer_fee.to_f).round(2)
      transfer_total           = sale.transfers.sum(:amount)
      sale.customer_balance    = (sale.working_capital.to_f - transfer_total).round(2)

      sale.sales_users.each do |su|
        pct = su.commission_pct_override.presence || su.commission_pct.to_f
        su.commission_amount = (nb * pct.to_f).round(2)
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
  end
end
