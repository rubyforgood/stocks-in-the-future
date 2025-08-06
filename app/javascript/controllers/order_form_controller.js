import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["shares", "totalCost", "currentPrice"]
  static values = { 
    currentPrice: Number 
  }

  calculateTotal() {
    const shares = parseInt(this.sharesTarget.value) || 0
    const price = this.currentPriceValue
    const total = shares * price
    
    this.totalCostTarget.textContent = `$${total}`
  }
}
