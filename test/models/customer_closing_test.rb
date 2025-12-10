require "test_helper"

class CustomerClosingTest < ActiveSupport::TestCase
  setup do
    @closing = Closing.create!(business_date: Date.current - 1.day, status: "open")
    @other_closing = Closing.create!(business_date: Date.current - 2.days, status: "open")
    @customer = Customer.create!(code: "CUSTZ", name: "Customer Z")
    @other_customer = Customer.create!(code: "CUSTX", name: "Customer X")
    @supplier = Supplier.create!(code: "SUPZ", name: "Supplier Z")
    @sale_seq = 0
    @customer_closing = CustomerClosing.create!(
      closing: @closing,
      customer: @customer,
      customer_balance: 100,
      receivables: 50
    )
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

  test "sales_for_closing returns only sales for the same closing and customer" do
    matching_sale = create_sale(code: "SALE1")
    create_sale(code: "SALE2", closing: @other_closing)
    create_sale(code: "SALE3", customer: @other_customer)

    assert_equal [ matching_sale ], @customer_closing.sales_for_closing
  end

  test "totals aggregates sales, transfers, and balance" do
    create_sale(
      code: "SALE10",
      gross_deposit: 100,
      net_base: 90,
      provider_commission: 10,
      customer_fee: 5,
      total_transfer_applied: 20,
      working_capital: 70,
      customer_balance: 60
    )
    create_sale(
      code: "SALE11",
      gross_deposit: 200,
      net_base: 180,
      provider_commission: 20,
      customer_fee: 10,
      total_transfer_applied: 40,
      working_capital: 140,
      customer_balance: 120
    )
    create_sale(code: "IGNORED", customer: @other_customer, gross_deposit: 999)
    create_direct_transfer(amount: 15)

    totals = @customer_closing.totals

    assert_in_delta 300, totals[:total_depositado].to_f
    assert_in_delta 270, totals[:total_despues_pcts].to_f
    assert_in_delta 60, totals[:transferencias].to_f
    assert_in_delta 15, totals[:transferencias_recibidas].to_f
    assert_in_delta 195, totals[:total_cliente].to_f
  end

  private

  def create_sale(attrs = {})
    @sale_seq += 1
    closing = attrs[:closing] || @closing
    defaults = {
      code: "SALE#{@sale_seq}",
      date: closing.business_date,
      customer: @customer,
      supplier: @supplier,
      closing: closing,
      gross_deposit: 100,
      net_base: 90,
      provider_commission: 10,
      customer_fee: 5,
      total_transfer_applied: 20,
      working_capital: 70,
      customer_balance: 60,
      status: "open"
    }

    Sale.create!(defaults.merge(attrs))
  end

  def create_direct_transfer(attrs = {})
    defaults = {
      code: "TR-DIRECT",
      amount: 10,
      customer: @customer,
      supplier: @supplier,
      from_entity: @supplier,
      to_entity: @customer,
      payment_method: "deposito",
      occurred_at: @closing.business_date.to_time.change(hour: 10)
    }

    Transfer.create!(defaults.merge(attrs))
  end
end
