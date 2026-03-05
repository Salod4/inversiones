require "test_helper"

class CustomerTest < ActiveSupport::TestCase
  test "valid customer" do
    customer = Customer.new(code: "CUST1", name: "Customer One", default_customer_fee_pct: 0.25)
    assert customer.valid?
  end

  test "requires code uniqueness" do
    Customer.create!(code: "CUST1", name: "Customer One")
    duplicate = Customer.new(code: "CUST1", name: "Customer Two")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:code], "has already been taken"
  end

  test "rejects customer fee pct below zero" do
    customer = Customer.new(code: "CUST2", name: "Customer Two", default_customer_fee_pct: -0.1)
    assert_not customer.valid?
    assert_includes customer.errors[:default_customer_fee_pct], "must be greater than or equal to 0"
  end

  test "has associations" do
    customer = Customer.new
    assert_respond_to customer, :sales
    assert_respond_to customer, :customer_closings
  end

  test "available_transfer_total decreases when transferring to fondo user" do
    customer = Customer.create!(code: "CUSTBAL", name: "Cliente Saldo")
    supplier = Supplier.create!(code: "SUPBAL", name: "Proveedor Saldo")
    fondo = User.create!(
      email: "fondo_customer_balance@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "FONDO",
      code: "FONDO"
    )

    Sale.create!(
      code: "SALE-CBAL",
      date: Date.current,
      customer: customer,
      supplier: supplier,
      gross_deposit: 100,
      net_base: 100,
      provider_pct: 0,
      customer_fee_pct: 0,
      provider_commission: 0,
      customer_fee: 0,
      working_capital: 100,
      customer_balance: 100,
      total_transfer_applied: 0,
      status: "open"
    )

    assert_equal BigDecimal("100"), customer.available_transfer_total

    Transfer.create!(
      from_entity: customer,
      to_entity: fondo,
      amount: 100
    )

    assert_equal BigDecimal("0"), customer.available_transfer_total
    assert_equal BigDecimal("100"), User.balances_by_user([ fondo.id ])[fondo.id]
  end
end
