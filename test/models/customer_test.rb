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

  test "rejects customer fee pct outside range" do
    customer = Customer.new(code: "CUST2", name: "Customer Two", default_customer_fee_pct: 1.1)
    assert_not customer.valid?
    assert_includes customer.errors[:default_customer_fee_pct], "must be less than 1"
  end

  test "has associations" do
    customer = Customer.new
    assert_respond_to customer, :sales
    assert_respond_to customer, :customer_closings
  end
end
