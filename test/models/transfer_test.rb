require "test_helper"

class TransferTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers
  setup do
    @customer = Customer.create!(code: "CUSTY", name: "Customer Y")
    @supplier = Supplier.create!(code: "SUPY", name: "Supplier Y")
    @sale = Sale.create!(
      code: "SALEY",
      date: Date.current,
      customer: @customer,
      supplier: @supplier,
      provider_pct: 0.2,
      customer_fee_pct: 0.1,
      gross_deposit: 1_000,
      net_base: 900,
      provider_commission: 100,
      customer_fee: 50,
      working_capital: 850,
      customer_balance: 850,
      total_transfer_applied: 0,
      status: "open"
    )
  end

  test "valid transfer" do
    transfer = Transfer.new(
      sale: @sale,
      customer: @customer,
      supplier: @supplier,
      amount: 500
    )
    assert transfer.valid?
  end

  test "requires positive amount" do
    transfer = Transfer.new(
      sale: @sale,
      customer: @customer,
      supplier: @supplier,
      amount: 0
    )

    assert_not transfer.valid?
    assert_includes transfer.errors[:amount], "must be greater than 0"
  end

  test "has associations" do
    transfer = Transfer.new
    assert_respond_to transfer, :sale
    assert_respond_to transfer, :customer
    assert_respond_to transfer, :supplier
  end

  test "cannot exceed sale available balance" do
    Transfer.create!(
      sale: @sale,
      customer: @customer,
      supplier: @supplier,
      amount: 800,
      code: "TRX-CAP",
      occurred_at: Time.current
    )

    transfer = Transfer.new(
      sale: @sale,
      customer: @customer,
      supplier: @supplier,
      amount: 200
    )

    assert_not transfer.valid?
    assert transfer.errors[:amount].any?
  end

  test "updates sale totals after saving" do
    transfer = Transfer.create!(
      sale: @sale,
      customer: @customer,
      supplier: @supplier,
      amount: 250,
      code: "TRX-UPDATE",
      occurred_at: Time.current
    )

    @sale.reload
    assert_equal 250, @sale.total_transfer_applied
    assert_equal(600, @sale.customer_balance.to_f)

    transfer.update!(amount: 300)
    @sale.reload
    assert_equal 300, @sale.total_transfer_applied
  end

  test "supplier must match sale" do
    other_supplier = Supplier.create!(code: "SUPZ", name: "Supplier Z")
    transfer = Transfer.new(
      sale: @sale,
      customer: @customer,
      supplier: other_supplier,
      amount: 50
    )

    assert_not transfer.valid?
    assert transfer.errors[:supplier_id].any?
  end

  test "generates unique code when base repeats" do
    freeze_time do
      first = Transfer.create!(
        sale: @sale,
        customer: @customer,
        supplier: @supplier,
        amount: 50
      )

      second = Transfer.create!(
        sale: @sale,
        customer: @customer,
        supplier: @supplier,
        amount: 60
      )

      refute_equal first.code, second.code
    end
  end

  test "can exist without sale" do
    transfer = Transfer.new(
      customer: @customer,
      supplier: @supplier,
      amount: 75
    )

    assert transfer.valid?
  end

  test "defaults occurred_at to open business date if today is closed" do
    travel_to Time.zone.local(2024, 1, 12, 10, 30) do
      Closing.create!(business_date: Date.new(2024, 1, 12), status: "closed")

      transfer = Transfer.create!(
        sale: @sale,
        customer: @customer,
        supplier: @supplier,
        amount: 50,
        code: "TRX-DATE"
      )

      assert_equal Date.new(2024, 1, 13), transfer.occurred_at.to_date
    end
  end

  test "allows same customer as origin and destination when transfer belongs to a sale" do
    transfer = Transfer.new(
      sale: @sale,
      customer: @customer,
      supplier: @supplier,
      from_entity: @customer,
      to_entity: @customer,
      amount: 50
    )

    assert transfer.valid?, transfer.errors.full_messages.to_sentence
  end
end
