# frozen_string_literal: true

module SalesHelper
  def sales_user_display_name(sale, sales_user)
    return fallback_sales_user_name(sales_user) unless sales_user.user&.code == "SUBAG"

    supplier_code = sale.supplier&.code
    customer_name = sale.customer&.name
    alias_name = Sales::Subagents.display_name_for(supplier_code, customer_name, sales_user.commission_pct)
    alias_name || fallback_sales_user_name(sales_user, default_label: "Subagente")
  end

  private

  def fallback_sales_user_name(sales_user, default_label: "Vendedor")
    sales_user.user&.name || sales_user.user&.email || default_label
  end
end
