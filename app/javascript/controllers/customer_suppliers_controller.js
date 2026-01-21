import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["suppliersContainer", "supplierTemplate"]
  static values = { defaultVendorIds: Array }

  addSupplier() {
    const stamp = this.uniqueStamp()
    const html = this.supplierTemplateTarget.innerHTML.replace(/NEW_SUPPLIER/g, stamp)
    this.suppliersContainerTarget.insertAdjacentHTML("beforeend", html)

    const supplierBlock = this.suppliersContainerTarget.lastElementChild
    if (!supplierBlock) return
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

    const stamp = this.uniqueStamp()
    const html = vendorTemplate.innerHTML.replace(/NEW_VENDOR/g, stamp)
    vendorContainer.insertAdjacentHTML("beforeend", html)

    if (!userId) return
    const row = vendorContainer.lastElementChild
    const userSelect = row?.querySelector("select[name*='[user_id]']")
    if (userSelect) userSelect.value = userId
  }

  uniqueStamp() {
    return `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`
  }
}
