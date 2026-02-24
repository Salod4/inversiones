require "test_helper"

class Sales::FeeResolutionTest < ActiveSupport::TestCase
  setup do
    @customer = Customer.create!(
      code: "CUST-FEE",
      name: "Cliente Fee",
      default_customer_fee_pct: 0.07
    )
    @supplier = Supplier.create!(
      code: "SUP-FEE",
      name: "Proveedor Fee",
      default_analysis_pct: 0.03
    )
  end

  test "prefill prioritizes customer default fee over provider-specific fee" do
    CustomerSupplier.create!(
      customer: @customer,
      supplier: @supplier,
      customer_fee_pct: 0.09
    )

    sale = Sale.new(customer: @customer, supplier: @supplier)
    Sales::Prefill.call(sale)

    assert_in_delta 0.03, sale.provider_pct.to_f, 0.00001
    assert_in_delta 0.07, sale.customer_fee_pct.to_f, 0.00001
  end

  test "prefill falls back to provider-specific fee when default fee is blank" do
    @customer.update!(default_customer_fee_pct: nil)
    CustomerSupplier.create!(
      customer: @customer,
      supplier: @supplier,
      customer_fee_pct: 0.05
    )

    sale = Sale.new(customer: @customer, supplier: @supplier)
    Sales::Prefill.call(sale)

    assert_in_delta 0.05, sale.customer_fee_pct.to_f, 0.00001
  end

  test "snapshot uses customer default fee even when provider-specific fee exists" do
    CustomerSupplier.create!(
      customer: @customer,
      supplier: @supplier,
      customer_fee_pct: 0.08
    )

    sale = Sale.new(
      customer: @customer,
      supplier: @supplier,
      gross_deposit: 1_160
    )

    Sales::SnapshotPcts.call(sale)

    assert_in_delta 0.03, sale.provider_pct.to_f, 0.00001
    assert_in_delta 0.07, sale.customer_fee_pct.to_f, 0.00001
  end
end
