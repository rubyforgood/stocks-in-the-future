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
    let shares = parseInt(this.sharesTarget.value, 10) || 0
  
    if (shares > 999_999_999_999) {
      shares = 999_999_999_999
    }
  
    this.sharesTarget.value = shares.toString()
  
    const price = this.currentPriceValue
    const total = shares * price
  
    this.totalCostTarget.textContent = `$${total.toFixed(2)}`
  }
}
