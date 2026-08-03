import { Controller } from "@hotwired/stimulus"

// Show/hide dialog for content already present in the page. Distinct from
// modal_controller, which streams its content into a turbo-frame.
//
// The trigger and the dialog are siblings rather than nested, so the controller
// is attached to a wrapper and the dialog is addressed as a target.
//
// Provides what the previous inline onclick handlers did not: Escape to close,
// focus moved into the dialog on open, focus trapped while open, and focus
// returned to the trigger on close.
const FOCUSABLE = [
  "a[href]",
  "button:not([disabled])",
  "input:not([disabled]):not([type='hidden'])",
  "select:not([disabled])",
  "textarea:not([disabled])",
  "[tabindex]:not([tabindex='-1'])"
].join(", ")

export default class extends Controller {
  static targets = ["dialog", "panel"]

  connect() {
    this._onKeydown = (e) => {
      if (!this._isOpen()) return
      if (e.key === "Escape") this.close()
      if (e.key === "Tab") this._trapTab(e)
    }
    document.addEventListener("keydown", this._onKeydown)
  }

  disconnect() {
    if (this._onKeydown) document.removeEventListener("keydown", this._onKeydown)
  }

  open(event) {
    if (event) event.preventDefault()
    if (!this.hasDialogTarget) return

    this.previouslyFocused = document.activeElement
    this.dialogTarget.classList.remove("hidden")
    requestAnimationFrame(() => {
      const items = this._focusableItems()
      const target = items[0] || this._panel()
      if (target && typeof target.focus === "function") target.focus()
    })
  }

  close(event) {
    if (event) event.preventDefault()
    if (!this.hasDialogTarget) return

    const wasOpen = this._isOpen()
    this.dialogTarget.classList.add("hidden")

    if (wasOpen && this.previouslyFocused && this.previouslyFocused.isConnected) {
      this.previouslyFocused.focus()
    }
    this.previouslyFocused = null
  }

  _isOpen() {
    return this.hasDialogTarget && !this.dialogTarget.classList.contains("hidden")
  }

  _panel() {
    return this.hasPanelTarget ? this.panelTarget : this.dialogTarget
  }

  _focusableItems() {
    return Array.from(this._panel().querySelectorAll(FOCUSABLE))
      .filter((el) => el.offsetParent !== null)
  }

  _trapTab(event) {
    const items = this._focusableItems()
    if (items.length === 0) {
      event.preventDefault()
      this._panel().focus()
      return
    }
    const first = items[0]
    const last = items[items.length - 1]

    if (!this._panel().contains(document.activeElement)) {
      event.preventDefault()
      first.focus()
    } else if (event.shiftKey && document.activeElement === first) {
      event.preventDefault()
      last.focus()
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault()
      first.focus()
    }
  }
}
