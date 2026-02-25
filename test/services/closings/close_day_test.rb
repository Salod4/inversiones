require "test_helper"

class Closings::CloseDayTest < ActiveSupport::TestCase
  test "ignores invalid opening balance references instead of failing the close" do
    business_date = Date.current
    customer = Customer.create!(code: "CLOSE-CUST", name: "Close Customer")
    supplier = Supplier.create!(code: "CLOSE-SUP", name: "Close Supplier")

    Sale.create!(
      code: "SALE-CLOSE-1",
      date: business_date,
      customer: customer,
      supplier: supplier,
      provider_pct: 0.01,
      customer_fee_pct: 0.02,
      gross_deposit: 1_000,
      net_base: 862.07,
      provider_commission: 8.62,
      customer_fee: 17.24,
      total_transfer_applied: 0,
      working_capital: 982.76,
      customer_balance: 982.76,
      status: "open"
    )

    # Simula datos legacy corruptos que no pasan validaciones de modelo.
    OpeningBalance.insert_all!(
      [
        {
          reference_type: OpeningBalance::TYPES[:customer],
          reference_id: nil,
          amount: 100,
          source: "legacy",
          created_at: Time.current,
          updated_at: Time.current
        },
        {
          reference_type: OpeningBalance::TYPES[:supplier],
          reference_id: nil,
          amount: 50,
          source: "legacy",
          created_at: Time.current,
          updated_at: Time.current
        }
      ]
    )

    assert_difference("Closing.count", 1) do
      Closings::CloseDay.new(business_date: business_date).call
    end

    closing = Closing.find_by!(business_date: business_date)
    assert_equal 1, closing.customer_closings.count
    assert_equal customer.id, closing.customer_closings.first.customer_id
    assert_equal 1, closing.supplier_closings.count
    assert_equal supplier.id, closing.supplier_closings.first.supplier_id
  end
end
