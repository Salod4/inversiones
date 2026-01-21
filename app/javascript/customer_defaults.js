function initCustomerDefaults() {
  const supplierContainer = document.getElementById("customer-suppliers-rows");
  const supplierTemplate = document.getElementById("customer-supplier-template");
  const addSupplier = document.getElementById("add-customer-supplier");
  const commissionContainer = document.getElementById("commission-defaults-rows");
  const commissionTemplate = document.getElementById("commission-default-template");
  const addCommission = document.getElementById("add-commission-default");

  if (!supplierContainer || !supplierTemplate || !addSupplier) return;
  if (!commissionContainer || !commissionTemplate || !addCommission) return;
  if (addSupplier.dataset.bound === "true") return;

  const addRow = (template, container) => {
    const stamp = `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
    const html = template.innerHTML.replace(/NEW_RECORD/g, stamp);
    container.insertAdjacentHTML("beforeend", html);
  };

  addSupplier.addEventListener("click", () => addRow(supplierTemplate, supplierContainer));
  addCommission.addEventListener("click", () => addRow(commissionTemplate, commissionContainer));
  addSupplier.dataset.bound = "true";
}

document.addEventListener("turbo:load", initCustomerDefaults);
document.addEventListener("DOMContentLoaded", initCustomerDefaults);
