require "test_helper"

class CustomersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @customer = Customer.create!(code: "CUST1", name: "Customer One")
  end

  test "should get index" do
    get customers_url
    assert_response :success
  end

  test "should get new" do
    get new_customer_url
    assert_response :success
  end

  test "should create customer" do
    assert_difference("Customer.count") do
      post customers_url, params: {
        customer: {
          code: "CUST2",
          name: "Customer Two",
          default_customer_fee_pct: 0.3
        }
      }
    end

    assert_redirected_to customer_url(Customer.last)
  end

  test "should show customer" do
    get customer_url(@customer)
    assert_response :success
  end

  test "should get edit" do
    get edit_customer_url(@customer)
    assert_response :success
  end

  test "should update customer" do
    patch customer_url(@customer), params: {
      customer: { name: "Updated Name" }
    }
    assert_redirected_to customer_url(@customer)
    @customer.reload
    assert_equal "Updated Name", @customer.name
  end

  test "should destroy customer" do
    assert_difference("Customer.count", -1) do
      delete customer_url(@customer)
    end
    assert_redirected_to customers_url
  end
end
