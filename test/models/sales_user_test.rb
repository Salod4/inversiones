require "test_helper"

class SalesUserTest < ActiveSupport::TestCase
  setup do
    customer = Customer.create!(code: "CUSTX", name: "Customer X")
    supplier = Supplier.create!(code: "SUPX", name: "Supplier X")
    @sale = Sale.create!(
      code: "SALEX",
      date: Date.current,
      customer: customer,
      supplier: supplier,
      provider_pct: 0.2,
      customer_fee_pct: 0.1,
      gross_deposit: 1_000,
      provider_commission: 100,
      total_transfer_applied: 0,
      status: "open"
    )
    @user = User.create!(
      email: "sales_user@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  test "valid sales user" do
    sales_user = SalesUser.new(
      sale: @sale,
      user: @user,
      commission_pct: 0.1,
      commission_amount: 50
    )
    assert sales_user.valid?
  end

  test "rejects commission pct outside range" do
    sales_user = SalesUser.new(
      sale: @sale,
      user: @user,
      commission_pct: 1.5
    )
    assert_not sales_user.valid?
    assert_includes sales_user.errors[:commission_pct], "must be less than 1"
  end

  test "rejects negative commission amount" do
    sales_user = SalesUser.new(
      sale: @sale,
      user: @user,
      commission_pct: 0.1,
      commission_amount: -5
    )

    assert_not sales_user.valid?
    assert_includes sales_user.errors[:commission_amount], "must be greater than or equal to 0"
  end

  test "has associations" do
    sales_user = SalesUser.new
    assert_respond_to sales_user, :sale
    assert_respond_to sales_user, :user
  end
end
