import { Controller } from "@hotwired/stimulus"

// Publishes the staging ribbon's rendered height as `--sitf-ribbon-h`, so the fixed header, the
// drawers and the content offset all follow it. See chrome.css for why this is measured rather than
// written down.
//
// A ResizeObserver rather than a resize listener: the ribbon's height changes when its text rewraps,
// which happens on zoom and on a font swap as well as on a viewport change, and only the element
// itself knows about all three. Figtree loading late is the ordinary case - the first measurement is
// taken against the fallback face.
export default class extends Controller {
  connect() {
    this.publish()
    this.observer = new ResizeObserver(() => this.publish())
    this.observer.observe(this.element)
  }

  disconnect() {
    this.observer?.disconnect()
    // Back to the no-ribbon value, or a cached page keeps a gap where the ribbon used to be.
    document.documentElement.style.setProperty("--sitf-ribbon-h", "0px")
  }

  publish() {
    const height = Math.round(this.element.getBoundingClientRect().height)
    document.documentElement.style.setProperty("--sitf-ribbon-h", `${height}px`)
  }
}
