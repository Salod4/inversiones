require "test_helper"

class ClosingTest < ActiveSupport::TestCase
  test "valid closing" do
    closing = Closing.new(
      business_date: Date.current,
      status: "open"
    )
    assert closing.valid?
  end

  test "requires business date" do
    closing = Closing.new(status: "open")
    assert_not closing.valid?
    assert_includes closing.errors[:business_date], "can't be blank"
  end

  test "rejects invalid status" do
    closing = Closing.new(business_date: Date.current, status: "invalid")
    assert_not closing.valid?
    assert_includes closing.errors[:status], "is not included in the list"
  end

  test "has associations" do
    closing = Closing.new
    assert_respond_to closing, :sales
    assert_respond_to closing, :customer_closings
    assert_respond_to closing, :supplier_closings
  end
end
