import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["shares", "totalCost", "currentPrice"]
  static values = {
    currentPrice: Number,
    transactionFee: Number
  }

  connect() {
    this.calculateTotal()
  }

  calculateTotal() {
    const shares = parseInt(this.sharesTarget.value) || 0
      if(shares === 0){
        this.totalCostTarget.textContent = "$0.00"
          return;
      }
    const price = this.currentPriceValue
    const total = shares * price + this.transactionFeeValue

    this.totalCostTarget.textContent = `$${total.toFixed(2)}`
  }
}
