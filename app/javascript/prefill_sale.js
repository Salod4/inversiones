function initSalePrefill() {
  const customer = document.getElementById("sale_customer_id");
  const supplier = document.getElementById("sale_supplier_id");
  const outProv  = document.getElementById("sale_provider_pct_override");
  const outCust  = document.getElementById("sale_customer_fee_pct_override");
  const outUsers = document.getElementById("preview_sales_users");
  let fetchToken = 0;

  if (!customer || !supplier || !outProv || !outCust || !outUsers) return;

  const fetchPrefill = async () => {
    if (!customer.value || !supplier.value) return;
    const selectedCustomerId = customer.value;
    const selectedSupplierId = supplier.value;
    const currentToken = ++fetchToken;
    const url = `/sales/prefill?customer_id=${encodeURIComponent(selectedCustomerId)}&supplier_id=${encodeURIComponent(selectedSupplierId)}`;
    const res = await fetch(url, { headers: { Accept: "application/json" } });
    if (!res.ok) return;

    const data = await res.json();
    if (currentToken !== fetchToken) return;
    if (customer.value !== selectedCustomerId || supplier.value !== selectedSupplierId) return;

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
          step="any"
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

function initCustomerSearch() {
  const searchInput = document.getElementById("sale_customer_search");
  const hiddenId    = document.getElementById("sale_customer_id");
  const resultsBox  = document.getElementById("sale_customer_results");

  if (!searchInput || !hiddenId || !resultsBox) return;
  if (searchInput.dataset.customerSearchBound) return;
  searchInput.dataset.customerSearchBound = "true";

  let customers = [];
  try {
    customers = JSON.parse(searchInput.dataset.customers || "[]");
  } catch (e) {
    console.error("Error parsing customers data", e);
    return;
  }

  const clearResults = () => {
    resultsBox.innerHTML = "";
  };

  const renderResults = (matches) => {
    clearResults();
    if (matches.length === 0) return;

    matches.forEach((c) => {
      const item = document.createElement("div");
      item.className = "customer-result-item";
      item.textContent = `${c.code} - ${c.name}`;

      item.addEventListener("click", () => {
        searchInput.value = `${c.code} - ${c.name}`;
        hiddenId.value = c.id;
        clearResults();

        const evt = new Event("change", { bubbles: true });
        hiddenId.dispatchEvent(evt);
      });

      resultsBox.appendChild(item);
    });
  };

  searchInput.addEventListener("input", () => {
    const term = searchInput.value.toLowerCase().trim();
    hiddenId.value = "";
    if (!term) {
      clearResults();
      return;
    }

    const matches = customers
      .filter((c) => `${c.code} - ${c.name}`.toLowerCase().includes(term))
      .slice(0, 20);

    renderResults(matches);
  });

  document.addEventListener("click", (e) => {
    if (!resultsBox.contains(e.target) && e.target !== searchInput) {
      clearResults();
    }
  });
}

document.addEventListener("turbo:load", () => {
  initSalePrefill();
  initCustomerSearch();
});

document.addEventListener("DOMContentLoaded", () => {
  initSalePrefill();
  initCustomerSearch();
});
