require "test_helper"

class SupplierTest < ActiveSupport::TestCase
  test "valid supplier" do
    supplier = Supplier.new(code: "SUP1", name: "Supplier One", default_analysis_pct: 0.5)
    assert supplier.valid?
  end

  test "requires unique code" do
    Supplier.create!(code: "SUP1", name: "Supplier One")
    duplicate = Supplier.new(code: "SUP1", name: "Other Supplier")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:code], "has already been taken"
  end

  test "rejects analysis pct outside range" do
    supplier = Supplier.new(code: "SUP2", name: "Supplier Two", default_analysis_pct: 1.1)
    assert_not supplier.valid?
    assert_includes supplier.errors[:default_analysis_pct], "must be less than 1"
  end

  test "has associations" do
    supplier = Supplier.new
    assert_respond_to supplier, :sales
    assert_respond_to supplier, :supplier_closings
    assert_respond_to supplier, :transfers
  end
end
