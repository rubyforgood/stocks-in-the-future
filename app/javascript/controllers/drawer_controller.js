import { Controller } from "@hotwired/stimulus"

// The mobile navigation drawer, shared by the app layout and the admin layout.
//
// It replaces two different mechanisms for one interaction: a hidden checkbox with
// peer-checked: utilities and four <label> wrappers in the app, and a controller toggling both
// a class and an inline style in admin. Neither carried aria-expanded, and the app's trigger
// was a <label> driving a checkbox, so assistive tech announced a checkbox rather than a
// control that opens navigation. Neither had Escape, a focus trap or focus return - and an open
// drawer is a modal surface over the page, so it needs all three.
//
// Above lg the sidebar is permanent, not a drawer, so every method no-ops there: trapping focus
// in a sidebar that is simply part of the page would be a bug.
const FOCUSABLE = [
  "a[href]",
  "button:not([disabled])",
  "input:not([disabled]):not([type='hidden'])",
  "select:not([disabled])",
  "textarea:not([disabled])",
  "[tabindex]:not([tabindex='-1'])"
].join(", ")

const CLOSED_CLASS = "-translate-x-full"
const DESKTOP = "(min-width: 64rem)"

export default class extends Controller {
  static targets = ["panel", "scrim", "trigger"]

  connect() {
    this._onKeydown = (event) => {
      if (event.key === "Escape" && this.isOpen) this.close()
      if (event.key === "Tab" && this.isOpen) this._trapTab(event)
    }
    document.addEventListener("keydown", this._onKeydown)

    // A Turbo visit replaces the body, but a restored cache preview can bring back an open
    // drawer over the new page. Closing on navigation is also what the <label> wrappers used to
    // do, one per row; the controller does it once.
    this._onNavigate = () => this._reset()
    document.addEventListener("turbo:before-visit", this._onNavigate)
  }

  disconnect() {
    document.removeEventListener("keydown", this._onKeydown)
    document.removeEventListener("turbo:before-visit", this._onNavigate)
  }

  get isDesktop() {
    return window.matchMedia(DESKTOP).matches
  }

  get isOpen() {
    return this.hasPanelTarget && !this.panelTarget.classList.contains(CLOSED_CLASS)
  }

  toggle(event) {
    if (event) event.preventDefault()
    this.isOpen ? this.close() : this.open()
  }

  open(event) {
    if (event) event.preventDefault()
    if (this.isDesktop || !this.hasPanelTarget) return

    this.previouslyFocused = document.activeElement
    this.panelTarget.classList.remove(CLOSED_CLASS)
    if (this.hasScrimTarget) this.scrimTarget.classList.remove("hidden")
    this._setExpanded(true)

    requestAnimationFrame(() => {
      const first = this._focusableItems()[0]
      if (first) first.focus()
    })
  }

  close(event) {
    if (event) event.preventDefault()
    if (!this.hasPanelTarget) return

    const wasOpen = this.isOpen
    this._reset()

    if (wasOpen && this.previouslyFocused && this.previouslyFocused.isConnected) {
      this.previouslyFocused.focus()
    }
    this.previouslyFocused = null
  }

  // Closes when a destination inside the drawer is chosen. Bound on the panel so it does not
  // need repeating on every row.
  closeIfLink(event) {
    if (this.isDesktop) return
    if (event.target.closest("a[href]")) this._reset()
  }

  _reset() {
    if (this.hasPanelTarget) this.panelTarget.classList.add(CLOSED_CLASS)
    if (this.hasScrimTarget) this.scrimTarget.classList.add("hidden")
    this._setExpanded(false)
  }

  _setExpanded(open) {
    if (this.hasTriggerTarget) this.triggerTarget.setAttribute("aria-expanded", String(open))
  }

  _focusableItems() {
    return Array.from(this.panelTarget.querySelectorAll(FOCUSABLE))
      .filter((el) => el.offsetParent !== null)
  }

  _trapTab(event) {
    const items = this._focusableItems()
    if (items.length === 0) return

    const first = items[0]
    const last = items[items.length - 1]

    if (!this.panelTarget.contains(document.activeElement)) {
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
