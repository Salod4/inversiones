# frozen_string_literal: true

class DashboardsController < ApplicationController
  def show
    @today = Date.current
    @sales_today_count = Sale.where(date: @today).count
    @closing_today = Closing.find_by(business_date: @today)
    @closing_done = @closing_today&.status == "closed"

    @seller_commissions_by_user = User.balances_by_user.reject { |_, total| total.to_d.zero? }

    @total_seller_commissions = @seller_commissions_by_user.values.sum

    customer_base = Sale.sum(:customer_balance).to_d +
      OpeningBalance.customers.sum(:amount).to_d +
      OpeningBalance.customer_groups.sum(:amount).to_d

    direct_customer_outgoing = 0.to_d
    Transfer.where(sale_id: nil, from_entity_type: "Customer").find_each do |transfer|
      direct_customer_outgoing += transfer.total_outgoing
    end

    direct_customer_incoming_from_customers = Transfer.where(
      sale_id: nil,
      to_entity_type: "Customer",
      from_entity_type: "Customer"
    ).sum(:amount).to_d

    direct_customer_incoming_from_others = Transfer.where(
      sale_id: nil,
      to_entity_type: "Customer"
    ).where.not(from_entity_type: "Customer").sum(:amount).to_d

    @customer_pending = customer_base - direct_customer_outgoing -
      direct_customer_incoming_from_others + direct_customer_incoming_from_customers

    @supplier_pending = Supplier.all.sum(&:available_transfer_total)
    @cash_box_total = Transfer.cash_box_balance

    loans = Loan.where("COALESCE(loans.amount,0) > COALESCE(loans.total_paid,0)")
                .order(created_at: :desc)
                .includes(:loan_payments)
    @loan_totals = {
      amount: loans.sum(:amount),
      paid: loans.sum(:total_paid),
      outstanding: loans.sum(&:balance)
    }
    @loans = loans

    @seller_names = {}
    User.where(id: @seller_commissions_by_user.keys).find_each do |u|
      label = u.name.presence || u.code.presence || u.email
      @seller_names[u.id] = label || "Vendedor"
    end
  end
end
