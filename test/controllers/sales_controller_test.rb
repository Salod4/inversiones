require "test_helper"

class SalesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:jack)
    sign_in @user

    @customer = Customer.create!(code: "CUST1", name: "Customer One")
    @supplier = Supplier.create!(code: "SUP1", name: "Supplier One")
    @closing = Closing.create!(business_date: Date.current, status: "open")
    @sale = Sale.create!(
      code: "SALE1",
      date: Date.current,
      customer: @customer,
      supplier: @supplier,
      closing: @closing,
      provider_pct: 0.2,
      customer_fee_pct: 0.1,
      gross_deposit: 1_000,
      net_base: 900,
      provider_commission: 100,
      customer_fee: 50,
      total_transfer_applied: 0,
      working_capital: 200,
      customer_balance: 150,
      status: "open"
    )
  end

  test "should get index" do
    get sales_url
    assert_response :success
  end

  test "should get new" do
    get new_sale_url
    assert_response :success
  end

  test "should create sale" do
    assert_difference("Sale.count") do
      post sales_url, params: {
        sale: {
          code: "SALE2",
          date: Date.current.to_s,
          customer_id: @customer.id,
          supplier_id: @supplier.id,
          closing_id: @closing.id,
          provider_pct: 0.25,
          customer_fee_pct: 0.1,
          gross_deposit: 500,
          net_base: 450,
          provider_commission: 50,
          customer_fee: 25,
          total_transfer_applied: 0,
          working_capital: 100,
          customer_balance: 75,
          status: "open"
        }
      }
    end

    assert_redirected_to sale_url(Sale.last)
  end

  test "should show sale" do
    get sale_url(@sale)
    assert_response :success
  end

  test "should get edit" do
    get edit_sale_url(@sale)
    assert_response :success
  end

  test "should update sale" do
    patch sale_url(@sale), params: {
      sale: { status: "closed" }
    }
    assert_redirected_to sale_url(@sale)
    @sale.reload
    assert_equal "closed", @sale.status
  end

  test "should destroy sale" do
    assert_difference("Sale.count", -1) do
      delete sale_url(@sale)
    end
    assert_redirected_to sales_url
  end
end
