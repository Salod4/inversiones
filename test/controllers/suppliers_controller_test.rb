require "test_helper"

class SuppliersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @supplier = Supplier.create!(code: "SUP1", name: "Supplier One")
  end

  test "should get index" do
    get suppliers_url
    assert_response :success
  end

  test "should get new" do
    get new_supplier_url
    assert_response :success
  end

  test "should create supplier" do
    assert_difference("Supplier.count") do
      post suppliers_url, params: {
        supplier: {
          code: "SUP2",
          name: "Supplier Two",
          default_analysis_pct: 0.25
        }
      }
    end

    assert_redirected_to supplier_url(Supplier.last)
  end

  test "should show supplier" do
    get supplier_url(@supplier)
    assert_response :success
  end

  test "should get edit" do
    get edit_supplier_url(@supplier)
    assert_response :success
  end

  test "should update supplier" do
    patch supplier_url(@supplier), params: {
      supplier: {
        name: "Updated Supplier"
      }
    }
    assert_redirected_to supplier_url(@supplier)
    @supplier.reload
    assert_equal "Updated Supplier", @supplier.name
  end

  test "should destroy supplier" do
    assert_difference("Supplier.count", -1) do
      delete supplier_url(@supplier)
    end

    assert_redirected_to suppliers_url
  end
end
