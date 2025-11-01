require "test_helper"

class SupplierClosingTest < ActiveSupport::TestCase
  setup do
    @closing = Closing.create!(business_date: Date.current, status: "open")
    @supplier = Supplier.create!(code: "SUPZ", name: "Supplier Z")
  end

  test "valid supplier closing" do
    supplier_closing = SupplierClosing.new(
      closing: @closing,
      supplier: @supplier,
      supplier_credit: 200,
      amount_owed_to_supplier: 150
    )
    assert supplier_closing.valid?
  end

  test "rejects non numeric values" do
    supplier_closing = SupplierClosing.new(
      closing: @closing,
      supplier: @supplier,
      supplier_credit: "abc"
    )

    assert_not supplier_closing.valid?
    assert_includes supplier_closing.errors[:supplier_credit], "is not a number"
  end

  test "has associations" do
    supplier_closing = SupplierClosing.new
    assert_respond_to supplier_closing, :closing
    assert_respond_to supplier_closing, :supplier
  end
end
