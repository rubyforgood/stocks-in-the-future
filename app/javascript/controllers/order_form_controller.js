import { Controller } from "@hotwired/stimulus"

// Two-step order form: enter the number of shares, then confirm.
//
// A trade is hard to undo once executed, so it gets a review step rather than
// submitting straight from the input. The review shows what the student is about
// to do plus the figure that was previously nowhere in the flow - the balance
// they will be left with.
//
// The server stays authoritative on affordability. The warning here is a nudge,
// not a gate, so a genuinely unaffordable order still reaches the server and
// gets its proper validation error.
export default class extends Controller {
  static targets = [
    "shares", "subtotal", "totalCost",
    "review", "reviewShares", "reviewTotal", "reviewBalance", "reviewWarning",
    "reviewButton", "submitButton", "backButton", "cancelButton"
  ]

  static values = {
    currentPrice: Number,
    fee: Number,
    balanceCents: Number,
    buying: Boolean
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
    const fee = this.hasFeeValue ? this.feeValue : 0

    // Buying costs the shares plus the fee, which is what the server validates
    // against. Selling credits the shares and the fee is still withheld, so net
    // proceeds are the subtotal minus the fee - not plus it.
    const total = this.buyingValue ? subtotal + fee : subtotal - fee

    if (this.hasSubtotalTarget) this.subtotalTarget.textContent = this.format(subtotal)
    this.totalCostTarget.textContent = this.format(total)

    this.shares = shares
    this.total = total
  }

  showReview(event) {
    if (event) event.preventDefault()
    this.calculateTotal()

    // Let the browser's own validation handle an empty or zero quantity, so the
    // review step never opens on a quantity that cannot be submitted.
    if (!this.sharesTarget.reportValidity() || this.shares < 1) return

    this.reviewSharesTarget.textContent = this.shares.toString()
    this.reviewTotalTarget.textContent = this.format(this.total)

    // this.total is already net of the fee in both directions.
    const balance = this.balanceCentsValue / 100
    const after = this.buyingValue ? balance - this.total : balance + this.total
    this.reviewBalanceTarget.textContent = this.format(after)

    const short = this.buyingValue && after < 0
    this.reviewWarningTarget.classList.toggle("hidden", !short)
    this.reviewWarningTarget.classList.toggle("flex", short)

    // Freeze the quantity so the review cannot drift out of sync with the input.
    this.sharesTarget.readOnly = true

    this.reviewTarget.classList.remove("hidden")
    this.reviewButtonTarget.classList.add("hidden")
    this.cancelButtonTarget.classList.add("hidden")
    this.backButtonTarget.classList.remove("hidden")
    this.submitButtonTarget.classList.remove("hidden")

    this.submitButtonTarget.focus()
  }

  backToEdit(event) {
    if (event) event.preventDefault()

    this.sharesTarget.readOnly = false

    this.reviewTarget.classList.add("hidden")
    this.reviewButtonTarget.classList.remove("hidden")
    this.cancelButtonTarget.classList.remove("hidden")
    this.backButtonTarget.classList.add("hidden")
    this.submitButtonTarget.classList.add("hidden")

    this.sharesTarget.focus()
  }

  format(amount) {
    return `$${amount.toFixed(2)}`
  }
}
