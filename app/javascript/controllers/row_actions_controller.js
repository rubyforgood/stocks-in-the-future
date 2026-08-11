import { Controller } from "@hotwired/stimulus"

// Anchors a row's actions popover to its trigger.
//
// A `popover` lives in the top layer, which is the point - an absolute panel inside the table's
// `overflow: auto` wrapper is clipped, measured at 508px against a 288px wrapper. The cost is that the top
// layer has no relationship to the trigger, so the browser centres it. This puts it back.
//
// Positioned in JS rather than with CSS anchor positioning: `position-anchor` is supported here (Chrome
// 151) and not in Safari or Firefox, and a menu that lands in the middle of the screen on one browser is
// not a menu. One code path everywhere.
//
// Without this controller the panel still opens - `popovertarget` is declarative - just unanchored. That
// is the right degradation for a control whose job is to reach an action.
export default class extends Controller {
  static targets = ["trigger", "panel"]

  connect() {
    this.reposition = this.reposition.bind(this)
  }

  disconnect() {
    this.stopTracking()
  }

  toggled(event) {
    if (event.newState === "open") {
      this.reposition()
      this.startTracking()
    } else {
      this.stopTracking()
    }
  }

  // While it is open the page can still move under it: the table scrolls sideways, the window resizes.
  // Capture phase, because scroll does not bubble.
  startTracking() {
    document.addEventListener("scroll", this.reposition, true)
    window.addEventListener("resize", this.reposition)
  }

  stopTracking() {
    document.removeEventListener("scroll", this.reposition, true)
    window.removeEventListener("resize", this.reposition)
  }

  reposition() {
    const trigger = this.triggerTarget.getBoundingClientRect()
    const panel = this.panelTarget.getBoundingClientRect()
    const gap = 4

    // Right-aligned to the trigger, because the trigger is at the end of the row.
    let left = trigger.right - panel.width
    let top = trigger.bottom + gap

    // Flip up rather than run off the bottom, and stay inside the viewport horizontally.
    if (top + panel.height > window.innerHeight - gap) {
      top = Math.max(gap, trigger.top - panel.height - gap)
    }
    left = Math.max(gap, Math.min(left, window.innerWidth - panel.width - gap))

    this.panelTarget.style.margin = "0"
    this.panelTarget.style.left = `${Math.round(left)}px`
    this.panelTarget.style.top = `${Math.round(top)}px`
  }
}
