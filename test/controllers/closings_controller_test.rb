require "test_helper"

class ClosingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @closing = Closing.create!(
      business_date: Date.current,
      status: "open",
      total_customers: 1,
      total_suppliers: 1,
      difference: 0
    )
  end

  test "should get index" do
    get closings_url
    assert_response :success
  end

  test "should get new" do
    get new_closing_url
    assert_response :success
  end

  test "should create closing" do
    assert_difference("Closing.count") do
      post closings_url, params: {
        closing: {
          business_date: Date.current + 1,
          status: "open",
          total_customers: 2,
          total_suppliers: 3,
          difference: 100,
          closed_at: Time.current
        }
      }
    end

    assert_redirected_to closing_url(Closing.last)
  end

  test "should show closing" do
    get closing_url(@closing)
    assert_response :success
  end

  test "should get edit" do
    get edit_closing_url(@closing)
    assert_response :success
  end

  test "should update closing" do
    patch closing_url(@closing), params: {
      closing: { status: "closed" }
    }
    assert_redirected_to closing_url(@closing)
    @closing.reload
    assert_equal "closed", @closing.status
  end

  test "should destroy closing" do
    assert_difference("Closing.count", -1) do
      delete closing_url(@closing)
    end
    assert_redirected_to closings_url
  end
end
