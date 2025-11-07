function initSalePrefill() {
  const customer = document.getElementById("sale_customer_id");
  const supplier = document.getElementById("sale_supplier_id");
  const outProv  = document.getElementById("preview_provider_pct");
  const outCust  = document.getElementById("preview_customer_fee_pct");
  const outUsers = document.getElementById("preview_sales_users");

  if (!customer || !supplier || !outProv || !outCust || !outUsers) return;

  const fetchPrefill = async () => {
    if (!customer.value || !supplier.value) return;
    const url = `/sales/prefill?customer_id=${customer.value}&supplier_id=${supplier.value}`;
    const res = await fetch(url, { headers: { Accept: "application/json" } });
    if (!res.ok) return;

    const data = await res.json();
    outProv.value = data.provider_pct ?? 0;
    outCust.value = data.customer_fee_pct ?? 0;

    outUsers.innerHTML = "";
    (data.sales_users || []).forEach((su) => {
      const row = document.createElement("div");
      row.dataset.userId = su.user_id;
      row.innerHTML = `
        <span>Vendedor #${su.user_id}</span>
        <input type="number" step="0.0001" name="sale[sales_users_attributes][][commission_pct_override]" placeholder="override opcional">
        <input type="hidden" name="sale[sales_users_attributes][][user_id]" value="${su.user_id}">
        <small>default: ${su.commission_pct}</small>
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
