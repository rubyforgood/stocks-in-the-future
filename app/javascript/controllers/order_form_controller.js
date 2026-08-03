import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["shares", "subtotal", "totalCost", "currentPrice"]
  static values = {
    currentPrice: Number,
    fee: Number
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

    const subtotal = shares * this.currentPriceValue

    // The trading fee has to be part of the displayed total. Previously this
    // showed shares x price only, while the server validated against
    // purchase_cost + transaction_fee - so the figure the student saw was not
    // the amount they were charged.
    const fee = this.hasFeeValue ? this.feeValue : 0
    const total = subtotal + fee

    if (this.hasSubtotalTarget) {
      this.subtotalTarget.textContent = this.format(subtotal)
    }
    this.totalCostTarget.textContent = this.format(total)
  }

  format(amount) {
    return `$${amount.toFixed(2)}`
  }
}
