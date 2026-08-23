import { Controller } from "@hotwired/stimulus"

// Selector for things a keyboard user can reach.
const FOCUSABLE = [
  "a[href]",
  "button:not([disabled])",
  "input:not([disabled]):not([type='hidden'])",
  "select:not([disabled])",
  "textarea:not([disabled])",
  "[tabindex]:not([tabindex='-1'])"
].join(", ")

export default class extends Controller {
  static targets = ["overlay", "content"]

  connect() {
    this.boundShowModal = this._show.bind(this)
    document.addEventListener("turbo:frame-load", this.boundShowModal)

    this._keydownHandler = (e) => {
      if (this._isOpen() && e.key === "Escape") {
        this.close()
      }
    }
    document.addEventListener("keydown", this._keydownHandler)

    // Keep focus inside the dialog while it is open (WCAG 2.1.2, no keyboard trap
    // out, but also no escaping the modal layer with Tab).
    this._trapHandler = (e) => this._trapTab(e)
    document.addEventListener("keydown", this._trapHandler)
  }

  disconnect() {
    if (this.boundShowModal) {
      document.removeEventListener("turbo:frame-load", this.boundShowModal)
    }
    if (this._keydownHandler) {
      document.removeEventListener("keydown", this._keydownHandler)
    }
    if (this._trapHandler) {
      document.removeEventListener("keydown", this._trapHandler)
    }
  }

  _show(event) {
    const frame = event.target
    if (frame.id === "modal_frame" && frame.innerHTML.trim() !== "") {
      this.show()
    }
  }

  show() {
    // Remember where focus came from so it can be handed back on close.
    this.previouslyFocused = document.activeElement
    this.overlayTarget.classList.remove("hidden")
    requestAnimationFrame(() => this._focusFirst())
  }

  close() {
    if (!this.hasOverlayTarget) return

    const wasOpen = this._isOpen()
    this.overlayTarget.classList.add("hidden")

    const frame = this.overlayTarget.querySelector("turbo-frame#modal_frame")
    if (frame) {
      frame.innerHTML = ""
    }

    // Return focus to whatever opened the dialog, so keyboard users are not
    // dropped back at the top of the document.
    if (wasOpen && this.previouslyFocused && this.previouslyFocused.isConnected) {
      this.previouslyFocused.focus()
    }
    this.previouslyFocused = null
  }

  backdropClick(event) {
    if (event.target === this.overlayTarget) {
      this.close()
    }
  }

  _isOpen() {
    return this.hasOverlayTarget && !this.overlayTarget.classList.contains("hidden")
  }

  _panel() {
    return this.hasContentTarget ? this.contentTarget : this.overlayTarget
  }

  _focusableItems() {
    return Array.from(this._panel().querySelectorAll(FOCUSABLE))
      .filter((el) => el.offsetParent !== null || el === document.activeElement)
  }

  _focusFirst() {
    if (!this._isOpen()) return
    const items = this._focusableItems()
    const target = items[0] || this._panel()
    if (target && typeof target.focus === "function") {
      target.focus()
    }
  }

  _trapTab(event) {
    if (event.key !== "Tab" || !this._isOpen()) return

    const items = this._focusableItems()
    if (items.length === 0) {
      event.preventDefault()
      this._panel().focus()
      return
    }

    const first = items[0]
    const last = items[items.length - 1]

    // If focus somehow sits outside the dialog, pull it back in.
    if (!this._panel().contains(document.activeElement)) {
      event.preventDefault()
      first.focus()
      return
    }

    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault()
      last.focus()
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault()
      first.focus()
    }
  }
}
