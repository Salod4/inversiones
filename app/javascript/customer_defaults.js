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

  const supplierSelect = supplierContainer.querySelector("select[name*='[supplier_id]']");
  let defaultSupplierId = supplierSelect ? supplierSelect.value : "";

  const commissionSupplierSelects = () =>
    commissionContainer.querySelectorAll("select[name*='[supplier_id]']");

  const syncCommissionSupplier = (newDefault, previousDefault = "") => {
    if (!newDefault) return;
    commissionSupplierSelects().forEach((select) => {
      if (!select.value || select.value === previousDefault) {
        select.value = newDefault;
      }
    });
  };

  const updateDefaultSupplier = () => {
    if (!supplierSelect) return;
    const previous = defaultSupplierId;
    defaultSupplierId = supplierSelect.value;
    if (defaultSupplierId && defaultSupplierId !== previous) {
      syncCommissionSupplier(defaultSupplierId, previous);
    }
  };

  if (supplierSelect) {
    supplierSelect.addEventListener("change", updateDefaultSupplier);
    updateDefaultSupplier();
  }

  addSupplier.addEventListener("click", () => addRow(supplierTemplate, supplierContainer));
  addCommission.addEventListener("click", () => {
    const beforeCount = commissionContainer.children.length;
    addRow(commissionTemplate, commissionContainer);
    const newRow = commissionContainer.children[beforeCount];
    if (!newRow) return;
    const select = newRow.querySelector("select[name*='[supplier_id]']");
    if (select && defaultSupplierId) {
      select.value = defaultSupplierId;
    }
  });
  addSupplier.dataset.bound = "true";
}

document.addEventListener("turbo:load", initCustomerDefaults);
document.addEventListener("DOMContentLoaded", initCustomerDefaults);
