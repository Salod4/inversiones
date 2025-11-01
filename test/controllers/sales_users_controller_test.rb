require "test_helper"

class SalesUsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    customer = Customer.create!(code: "CUST1", name: "Customer One")
    supplier = Supplier.create!(code: "SUP1", name: "Supplier One")
    @sale = Sale.create!(
      code: "SALE1",
      date: Date.current,
      customer: customer,
      supplier: supplier,
      provider_pct: 0.2,
      customer_fee_pct: 0.1,
      gross_deposit: 1_000,
      provider_commission: 100,
      total_transfer_applied: 0,
      status: "open"
    )
    @user = User.create!(
      email: "seller@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  test "should get new" do
    get new_sale_sales_user_url(@sale)
    assert_response :success
  end

  test "should create sales user" do
    another_user = User.create!(
      email: "seller2@example.com",
      password: "password",
      password_confirmation: "password"
    )

    assert_difference("SalesUser.count") do
      post sale_sales_users_url(@sale), params: {
        sales_user: {
          user_id: another_user.id,
          commission_pct: 0.1,
          commission_amount: 50
        }
      }
    end

    assert_redirected_to sale_url(@sale)
  end

  test "should destroy sales user" do
    sales_user = SalesUser.create!(
      sale: @sale,
      user: @user,
      commission_pct: 0.1,
      commission_amount: 50
    )

    assert_difference("SalesUser.count", -1) do
      delete sale_sales_user_url(@sale, sales_user)
    end

    assert_redirected_to sale_url(@sale)
  end
end
