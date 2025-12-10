require "test_helper"

class SupplierClosingTest < ActiveSupport::TestCase
  setup do
    @closing = Closing.create!(business_date: Date.current - 1.day, status: "open")
    @other_closing = Closing.create!(business_date: Date.current - 2.days, status: "open")
    @supplier = Supplier.create!(code: "SUPZ", name: "Supplier Z")
    @customer = Customer.create!(code: "CUSTZ", name: "Customer Z")
    @other_supplier = Supplier.create!(code: "SUPX", name: "Supplier X")
    @sale_seq = 0
    @supplier_closing = SupplierClosing.create!(
      closing: @closing,
      supplier: @supplier,
      supplier_credit: 200,
      amount_owed_to_supplier: 150
    )
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

  test "sales_for_closing returns only sales for the same closing and supplier" do
    matching_sale = create_sale(code: "SALE1")
    create_sale(code: "SALE2", closing: @other_closing)
    create_sale(code: "SALE3", supplier: @other_supplier)

    assert_equal [ matching_sale ], @supplier_closing.sales_for_closing
  end

  test "totals aggregates sales and transfers for the closing" do
    sale_one = create_sale(
      code: "SALE10",
      gross_deposit: 100,
      net_base: 90,
      provider_commission: 10,
      total_transfer_applied: 20,
      working_capital: 70,
      customer_balance: 60
    )
    sale_two = create_sale(
      code: "SALE11",
      gross_deposit: 200,
      net_base: 180,
      provider_commission: 20,
      total_transfer_applied: 40,
      working_capital: 140,
      customer_balance: 120
    )
    create_sale(code: "IGNORED", supplier: @other_supplier)
    other_sale = create_sale(code: "SALE-OTH", closing: @other_closing, supplier: @other_supplier)

    create_transfer(code: "TR1", amount: 50, sale: sale_one)
    create_transfer(code: "TR2", amount: 25, sale: sale_two)
    create_transfer(code: "TR-OTHER", amount: 100, sale: other_sale, occurred_at: @other_closing.business_date.noon)

    totals = @supplier_closing.totals

    assert_in_delta @supplier.default_analysis_pct.to_f, totals[:analisis_base_pct].to_f
    assert_in_delta 300, totals[:total_asignado].to_f
    assert_in_delta 270, totals[:ret_comp_total].to_f
    assert_in_delta 75, totals[:transferido].to_f
    assert_in_delta 195, totals[:saldo_pendiente].to_f
  end

  private

  def create_sale(attrs = {})
    @sale_seq += 1
    closing = attrs[:closing] || @closing
    supplier = attrs[:supplier] || @supplier

    defaults = {
      code: "SALE#{@sale_seq}",
      date: closing.business_date,
      customer: @customer,
      supplier: supplier,
      closing: closing,
      gross_deposit: 100,
      net_base: 90,
      provider_commission: 10,
      total_transfer_applied: 20,
      working_capital: 200,
      customer_balance: 60,
      status: "open"
    }

    Sale.create!(defaults.merge(attrs))
  end

  def create_transfer(attrs = {})
    sale = attrs[:sale] || create_sale
    occurred_at = attrs[:occurred_at] || sale.date.to_time.change(hour: 12)

    defaults = {
      sale: sale,
      supplier: sale.supplier,
      customer: sale.customer,
      from_entity: sale.customer,
      to_entity: sale.supplier,
      amount: 50,
      occurred_at: occurred_at,
      payment_method: "deposito"
    }

    Transfer.create!(defaults.merge(attrs))
  end
end
