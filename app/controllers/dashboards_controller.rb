# frozen_string_literal: true

class DashboardsController < ApplicationController
  def show
    @today = Date.current
    @sales_today_count = Sale.where(date: @today).count
    @closing_today = Closing.find_by(business_date: @today)
    @closing_done = @closing_today&.status == "closed"

    commissions = SalesUser.group(:user_id).sum(:commission_amount)
    openings = OpeningBalance.users.group(:reference_id).sum(:amount)
    merged = commissions.dup
    openings.each { |uid, amt| merged[uid] = merged.fetch(uid, 0).to_d + amt.to_d }
    @seller_commissions_by_user = merged

    @total_seller_commissions = @seller_commissions_by_user.values.sum

    @customer_pending = Sale.sum(:customer_balance).to_d +
      OpeningBalance.customers.sum(:amount).to_d +
      OpeningBalance.customer_groups.sum(:amount).to_d

    @supplier_pending = Supplier.all.sum(&:available_transfer_total)

    @seller_names = {}
    User.where(id: @seller_commissions_by_user.keys).find_each do |u|
      label = u.name.presence || u.code.presence || u.email
      @seller_names[u.id] = label || "Vendedor"
    end
  end
end
