require "test_helper"

class SaleTest < ActiveSupport::TestCase
  setup do
    @customer = Customer.create!(code: "C1", name: "Customer One")
    @supplier = Supplier.create!(code: "S1", name: "Supplier One")
  end

  def build_sale
    Sale.new(
      code: "SALE1",
      date: Date.current,
      customer: @customer,
      supplier: @supplier,
      provider_pct: 0.2,
      customer_fee_pct: 0.1,
      gross_deposit: 1_000,
      provider_commission: 100,
      total_transfer_applied: 0,
      status: "open"
    )
  end

  test "valid sale" do
    sale = build_sale
    assert sale.valid?
  end

  test "rejects invalid status" do
    sale = build_sale
    sale.status = "unknown"

    assert_not sale.valid?
    assert_includes sale.errors[:status], "is not included in the list"
  end

  test "enforces max sellers" do
    sale = build_sale
    (Sale::MAX_SELLERS + 1).times do |index|
      user = User.create!(
        email: "user#{index}@example.com",
        password: "password",
        password_confirmation: "password"
      )
      sale.sales_users.build(user: user, commission_pct: 0.05, commission_amount: 10)
    end

    assert_not sale.valid?
    assert_includes sale.errors[:sales_users], "exceeds the maximum of #{Sale::MAX_SELLERS} sellers per sale"
  end
end
