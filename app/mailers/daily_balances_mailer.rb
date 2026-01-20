class DailyBalancesMailer < ApplicationMailer
  def summary
    recipients = recipient_emails
    return if recipients.empty?

    @as_of = Time.zone.now
    @customers = build_customer_rows
    @suppliers = build_supplier_rows
    @loans = build_loan_rows
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
