import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["shares", "totalCost", "currentPrice"]
  static values = {
    currentPrice: Number,
  }

  connect() {
    this.calculateTotal()
  }

  calculateTotal() {
    const rawValue = this.sharesTarget.value || ""
    const sanitized = rawValue.replace(/\D+/g, "")
    if (sanitized !== rawValue) {
      this.sharesTarget.value = sanitized
    }
    const shares = parseInt(sanitized || "0", 10)

    const price = this.currentPriceValue
    const total = shares * price

    this.totalCostTarget.textContent = `$${total.toFixed(2)}`
  }
}
