require "test_helper"

class TransfersControllerTest < ActionDispatch::IntegrationTest
  setup do
    customer = Customer.create!(code: "CUST1", name: "Customer One")
    @supplier = Supplier.create!(code: "SUP1", name: "Supplier One")
    @sale = Sale.create!(
      code: "SALE1",
      date: Date.current,
      customer: customer,
      supplier: @supplier,
      provider_pct: 0.2,
      customer_fee_pct: 0.1,
      gross_deposit: 1_000,
      net_base: 900,
      provider_commission: 100,
      customer_fee: 50,
      working_capital: 850,
      customer_balance: 850,
      total_transfer_applied: 0,
      status: "open"
    )
    @transfer = Transfer.create!(
      sale: @sale,
      supplier: @supplier,
      amount: 150,
      code: "TRX1",
      occurred_at: Time.current
    )
  end

  test "should get index" do
    get sale_transfers_url(@sale)
    assert_response :success
  end

  test "should get new" do
    get new_sale_transfer_url(@sale)
    assert_response :success
  end

  test "should create transfer" do
    assert_difference("Transfer.count") do
      post sale_transfers_url(@sale), params: {
        transfer: {
          supplier_id: @supplier.id,
          from_entity_ref: "Customer:#{@sale.customer_id}",
          destination_entries: [
            {
              to_entity_ref: "Supplier:#{@supplier.id}",
              amount: 200
            }
          ],
          note: "Test transfer"
        }
      }
    end

    assert_redirected_to sale_transfers_url(@sale)
  end

  test "creates multiple transfers in one request" do
    assert_difference("Transfer.count", 2) do
      post sale_transfers_url(@sale), params: {
        transfer: {
          supplier_id: @supplier.id,
          from_entity_ref: "Customer:#{@sale.customer_id}",
          destination_entries: [
            { to_entity_ref: "Supplier:#{@supplier.id}", amount: 100 },
            { to_entity_ref: "Supplier:#{@supplier.id}", amount: 50 }
          ]
        }
      }
    end

    assert_redirected_to sale_transfers_url(@sale)
  end

  test "rejects batch that exceeds available balance" do
    assert_no_difference("Transfer.count") do
      post sale_transfers_url(@sale), params: {
        transfer: {
          supplier_id: @supplier.id,
          from_entity_ref: "Customer:#{@sale.customer_id}",
          destination_entries: [
            { to_entity_ref: "Supplier:#{@supplier.id}", amount: 500 },
            { to_entity_ref: "Supplier:#{@supplier.id}", amount: 400 }
          ]
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should show transfer" do
    get transfer_url(@transfer)
    assert_response :success
  end

  test "should get edit" do
    get edit_transfer_url(@transfer)
    assert_response :success
  end

  test "should update transfer" do
    patch transfer_url(@transfer), params: {
      transfer: { note: "Updated note" }
    }
    assert_redirected_to transfer_url(@transfer)
    @transfer.reload
    assert_equal "Updated note", @transfer.note
  end

  test "should destroy transfer" do
    assert_difference("Transfer.count", -1) do
      delete transfer_url(@transfer)
    end

    assert_redirected_to sale_transfers_url(@sale)
  end
end
