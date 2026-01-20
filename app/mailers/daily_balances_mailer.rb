class DailyBalancesMailer < ApplicationMailer
  def summary
    recipients = recipient_emails
    return if recipients.empty?

    @as_of = Time.zone.now
    @sellers = build_seller_rows
    @customers = build_customer_rows
    @suppliers = build_supplier_rows
    @loans = build_loan_rows
    @seller_total = sum_rows(@sellers)
    @customer_total = sum_rows(@customers)
    @supplier_total = sum_rows(@suppliers)
    @loan_total = sum_rows(@loans)

    mail(
      to: recipients,
      subject: "Reporte diario de saldos - #{I18n.l(@as_of.to_date)}"
    )
  end

  private

  def recipient_emails
    raw = ENV.fetch("DAILY_BALANCES_EMAIL", "juanjos.finance@gmail.com")
    raw.split(/[,\s;]/).reject(&:blank?)
  end

  def build_customer_rows
    customers = Customer.order(:name).to_a
    rows = customers.map do |customer|
      {
        name: customer.name,
        code: customer.code,
        balance: customer.available_transfer_total
      }
    end
    rows.select { |row| row[:balance].to_d.positive? }
        .sort_by { |row| -row[:balance].to_d }
  end

  def build_seller_rows
    users = User.order(:name).to_a
    commissions = SalesUser.group(:user_id).sum(:commission_amount)
    openings = OpeningBalance.users.group(:reference_id).sum(:amount)

    rows = users.map do |user|
      {
        name: user.name,
        code: user.code,
        balance: commissions.fetch(user.id, 0).to_d + openings.fetch(user.id, 0).to_d
      }
    end

    rows.select { |row| row[:balance].to_d.positive? }
        .sort_by { |row| -row[:balance].to_d }
  end

  def build_supplier_rows
    suppliers = Supplier.order(:name).to_a
    rows = suppliers.map do |supplier|
      {
        name: supplier.name,
        code: supplier.code,
        balance: supplier.available_transfer_total
      }
    end
    rows.select { |row| row[:balance].to_d.positive? }
        .sort_by { |row| -row[:balance].to_d }
  end

  def build_loan_rows
    loans = Loan.where("COALESCE(loans.amount,0) > COALESCE(loans.total_paid,0)").order(:name)
    loans.map do |loan|
      {
        name: loan.name,
        balance: loan.balance
      }
    end
  end

  def sum_rows(rows)
    rows.sum { |row| row[:balance].to_d }
  end
end
