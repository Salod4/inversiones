function initSalePrefill() {
  const customer = document.getElementById("sale_customer_id");
  const supplier = document.getElementById("sale_supplier_id");
  const outProv  = document.getElementById("sale_provider_pct_override");
  const outCust  = document.getElementById("sale_customer_fee_pct_override");
  const outUsers = document.getElementById("preview_sales_users");

  if (!customer || !supplier || !outProv || !outCust || !outUsers) return;

  const fetchPrefill = async () => {
    if (!customer.value || !supplier.value) return;
    const url = `/sales/prefill?customer_id=${customer.value}&supplier_id=${supplier.value}`;
    const res = await fetch(url, { headers: { Accept: "application/json" } });
    if (!res.ok) return;

    const data = await res.json();
    outProv.value = data.provider_pct ?? "";
    outCust.value = data.customer_fee_pct ?? "";

    outUsers.innerHTML = "";
    (data.sales_users || []).forEach((su) => {
      const row = document.createElement("div");
      row.dataset.userId = su.user_id;
      row.innerHTML = `
        <label>${su.user_name || "Vendedor"} (${su.commission_pct})</label>
        <input
          type="number"
          step="0.0001"
          name="sale[sales_users_attributes][][commission_pct_override]"
          placeholder="${su.commission_pct}"
        >
        <input type="hidden" name="sale[sales_users_attributes][][user_id]" value="${su.user_id}">
      `;
      outUsers.appendChild(row);
    });
  };

  const bindIfNeeded = (element) => {
    if (!element || element.dataset.prefillBound) return;
    element.addEventListener("change", fetchPrefill);
    element.dataset.prefillBound = "true";
  };

  bindIfNeeded(customer);
  bindIfNeeded(supplier);
  fetchPrefill();
}

document.addEventListener("turbo:load", initSalePrefill);
document.addEventListener("DOMContentLoaded", initSalePrefill);
