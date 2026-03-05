require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "balances_by_user includes commissions openings and transfers" do
    user = User.create!(
      email: "fondo_balance@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "FONDO",
      code: "FONDO"
    )
    customer = Customer.create!(code: "CUSFB", name: "Cliente Balance")
    supplier = Supplier.create!(code: "SUPFB", name: "Proveedor Balance")
    sale = Sale.create!(
      code: "SALE-FB",
      date: Date.current,
      customer: customer,
      supplier: supplier,
      gross_deposit: 1_000,
      net_base: 1_000,
      provider_pct: 0,
      customer_fee_pct: 0,
      provider_commission: 0,
      customer_fee: 0,
      working_capital: 1_000,
      customer_balance: 1_000,
      total_transfer_applied: 0,
      status: "open"
    )

    SalesUser.create!(sale: sale, user: user, commission_pct: 0.02, commission_amount: 20)
    OpeningBalance.create!(reference_type: OpeningBalance::TYPES[:user], reference_id: user.id, amount: 10)

    Transfer.create!(
      customer: customer,
      supplier: supplier,
      from_entity: customer,
      to_entity: user,
      amount: 100
    )
    Transfer.create!(
      customer: customer,
      supplier: supplier,
      from_entity: user,
      to_entity: customer,
      amount: 30
    )

    balances = User.balances_by_user([ user.id ])
    assert_equal BigDecimal("100"), balances[user.id]
  end
end
