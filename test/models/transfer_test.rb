require "test_helper"

class TransferTest < ActiveSupport::TestCase
  setup do
    customer = Customer.create!(code: "CUSTY", name: "Customer Y")
    @supplier = Supplier.create!(code: "SUPY", name: "Supplier Y")
    @sale = Sale.create!(
      code: "SALEY",
      date: Date.current,
      customer: customer,
      supplier: @supplier,
      provider_pct: 0.2,
      customer_fee_pct: 0.1,
      gross_deposit: 1_000,
      provider_commission: 100,
      total_transfer_applied: 0,
      status: "open"
    )
  end

  test "valid transfer" do
    transfer = Transfer.new(
      sale: @sale,
      supplier: @supplier,
      amount: 500
    )
    assert transfer.valid?
  end

  test "requires positive amount" do
    transfer = Transfer.new(
      sale: @sale,
      supplier: @supplier,
      amount: 0
    )

    assert_not transfer.valid?
    assert_includes transfer.errors[:amount], "must be greater than 0"
  end

  test "has associations" do
    transfer = Transfer.new
    assert_respond_to transfer, :sale
    assert_respond_to transfer, :supplier
  end
end
