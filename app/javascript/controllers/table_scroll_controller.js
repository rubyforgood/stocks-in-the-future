import { Controller } from "@hotwired/stimulus"

// Marks a horizontally scrolled table so the pinned actions cell can show its separator only when
// there is something behind it to separate from.
//
// The separator used to be unconditional below lg. On a table that does not scroll - the student
// portfolio's holdings, which adapts by wrapping its company name instead - that drew a stray
// vertical rule beside the Trade button, and an opaque cell that swallowed the row's hover tint.
//
// One controller on <body> rather than an attribute on all eleven scroll wrappers: scroll events do
// not bubble, but they do fire during the capture phase, so a single capturing listener sees every
// scroll in the document.
export default class extends Controller {
  connect() {
    this.onScroll = this.onScroll.bind(this)
    document.addEventListener("scroll", this.onScroll, true)
  }

  disconnect() {
    document.removeEventListener("scroll", this.onScroll, true)
  }

  onScroll(event) {
    const el = event.target
    if (!(el instanceof Element)) return

    const overflow = getComputedStyle(el).overflowX
    if (overflow !== "auto" && overflow !== "scroll") return

    // A string, not a boolean: the CSS selector matches on the value.
    el.dataset.tableScrolled = el.scrollLeft > 0 ? "true" : "false"
  }
}
