require "test_helper"

class SupplierClosingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:jack)
    sign_in @user

    @closing = Closing.create!(business_date: Date.current, status: "open")
    @supplier = Supplier.create!(code: "SUP1", name: "Supplier One")
    @supplier_closing = SupplierClosing.create!(
      closing: @closing,
      supplier: @supplier,
      supplier_credit: 150,
      amount_owed_to_supplier: 75
    )
  end

  test "should get index" do
    get closing_supplier_closings_url(@closing)
    assert_response :success
  end

  test "should get new" do
    get new_closing_supplier_closing_url(@closing)
    assert_response :success
  end

  test "should create supplier closing" do
    new_supplier = Supplier.create!(code: "SUP2", name: "Supplier Two")

    assert_difference("SupplierClosing.count") do
      post closing_supplier_closings_url(@closing), params: {
        supplier_closing: {
          supplier_id: new_supplier.id,
          supplier_credit: 175,
          amount_owed_to_supplier: 90
        }
      }
    end

    assert_redirected_to closing_url(@closing)
  end

  test "should show supplier closing" do
    get closing_supplier_closing_url(@closing, @supplier_closing)
    assert_response :success
  end

  test "should get edit" do
    get edit_closing_supplier_closing_url(@closing, @supplier_closing)
    assert_response :success
  end

  test "should update supplier closing" do
    patch closing_supplier_closing_url(@closing, @supplier_closing), params: {
      supplier_closing: { supplier_credit: 200 }
    }
    assert_redirected_to closing_url(@closing)
    @supplier_closing.reload
    assert_equal 200, @supplier_closing.supplier_credit.to_i
  end

  test "should destroy supplier closing" do
    assert_difference("SupplierClosing.count", -1) do
      delete closing_supplier_closing_url(@closing, @supplier_closing)
    end
    assert_redirected_to closing_url(@closing)
  end

  test "should get pdf" do
    get pdf_closing_supplier_closing_url(@closing, @supplier_closing)

    assert_response :success
    assert_includes @response.headers["Content-Type"], "application/pdf"
    assert_not_empty @response.body
  end
end
