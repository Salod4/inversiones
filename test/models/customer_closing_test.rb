require "test_helper"

class CustomerClosingTest < ActiveSupport::TestCase
  setup do
    @closing = Closing.create!(business_date: Date.current, status: "open")
    @customer = Customer.create!(code: "CUSTZ", name: "Customer Z")
  end

  test "valid customer closing" do
    customer_closing = CustomerClosing.new(
      closing: @closing,
      customer: @customer,
      customer_balance: 100,
      receivables: 50
    )
    assert customer_closing.valid?
  end

  test "rejects non numeric values" do
    customer_closing = CustomerClosing.new(
      closing: @closing,
      customer: @customer,
      customer_balance: "abc"
    )

    assert_not customer_closing.valid?
    assert_includes customer_closing.errors[:customer_balance], "is not a number"
  end

  test "has associations" do
    customer_closing = CustomerClosing.new
    assert_respond_to customer_closing, :closing
    assert_respond_to customer_closing, :customer
  end
end
