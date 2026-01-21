import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["suppliersContainer", "supplierTemplate"]
  static values = { defaultVendorIds: Array }

  connect() {
    const supplierBlocks = this.suppliersContainerTarget.querySelectorAll("[data-supplier-block]")
    this.supplierIndex = supplierBlocks.length
    supplierBlocks.forEach((block) => {
      const count = block.querySelectorAll("[data-vendor-row]").length
      block.dataset.vendorIndex = count.toString()
    })
  }

  addSupplier() {
    const stamp = this.nextSupplierIndex()
    const html = this.supplierTemplateTarget.innerHTML.replace(/NEW_SUPPLIER/g, stamp)
    this.suppliersContainerTarget.insertAdjacentHTML("beforeend", html)

    const supplierBlock = this.suppliersContainerTarget.lastElementChild
    if (!supplierBlock) return
    supplierBlock.dataset.vendorIndex = "0"
    this.preloadVendors(supplierBlock)
  }

  addVendor(event) {
    const supplierBlock = event.target.closest("[data-supplier-block]")
    if (!supplierBlock) return
    this.appendVendorRow(supplierBlock)
  }

  preloadVendors(supplierBlock) {
    const ids = this.defaultVendorIdsValue || []
    ids.forEach((userId) => this.appendVendorRow(supplierBlock, userId))
  }

  appendVendorRow(supplierBlock, userId = null) {
    const vendorTemplate = supplierBlock.querySelector("[data-vendor-template]")
    const vendorContainer = supplierBlock.querySelector("[data-vendor-container]")
    if (!vendorTemplate || !vendorContainer) return

    const stamp = this.nextVendorIndex(supplierBlock)
    const html = vendorTemplate.innerHTML.replace(/NEW_VENDOR/g, stamp)
    vendorContainer.insertAdjacentHTML("beforeend", html)

    if (!userId) return
    const row = vendorContainer.lastElementChild
    const userSelect = row?.querySelector("select[name*='[user_id]']")
    if (userSelect) userSelect.value = userId
  }

  nextSupplierIndex() {
    const current = this.supplierIndex || 0
    this.supplierIndex = current + 1
    return current
  }

  nextVendorIndex(supplierBlock) {
    const current = Number.parseInt(supplierBlock.dataset.vendorIndex || "0", 10)
    supplierBlock.dataset.vendorIndex = (current + 1).toString()
    return current
  }
}
