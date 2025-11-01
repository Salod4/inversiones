require "test_helper"

class CustomerClosingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @closing = Closing.create!(business_date: Date.current, status: "open")
    @customer = Customer.create!(code: "CUST1", name: "Customer One")
    @customer_closing = CustomerClosing.create!(
      closing: @closing,
      customer: @customer,
      customer_balance: 100,
      receivables: 50
    )
  end

  test "should get index" do
    get closing_customer_closings_url(@closing)
    assert_response :success
  end

  test "should get new" do
    get new_closing_customer_closing_url(@closing)
    assert_response :success
  end

  test "should create customer closing" do
    new_customer = Customer.create!(code: "CUST2", name: "Customer Two")

    assert_difference("CustomerClosing.count") do
      post closing_customer_closings_url(@closing), params: {
        customer_closing: {
          customer_id: new_customer.id,
          customer_balance: 200,
          receivables: 75
        }
      }
    end

    assert_redirected_to closing_url(@closing)
  end

  test "should show customer closing" do
    get closing_customer_closing_url(@closing, @customer_closing)
    assert_response :success
  end

  test "should get edit" do
    get edit_closing_customer_closing_url(@closing, @customer_closing)
    assert_response :success
  end

  test "should update customer closing" do
    patch closing_customer_closing_url(@closing, @customer_closing), params: {
      customer_closing: { customer_balance: 125 }
    }
    assert_redirected_to closing_url(@closing)
    @customer_closing.reload
    assert_equal 125, @customer_closing.customer_balance.to_i
  end

  test "should destroy customer closing" do
    assert_difference("CustomerClosing.count", -1) do
      delete closing_customer_closing_url(@closing, @customer_closing)
    end

    assert_redirected_to closing_url(@closing)
  end
end
