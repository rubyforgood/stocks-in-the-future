import { Controller } from "@hotwired/stimulus"

// Publishes an element's rendered height as a CSS custom property, so the things below it can be
// positioned against what it actually measures rather than against a number somebody wrote down.
//
// Two elements use it: the staging band (`--sitf-ribbon-h`) and the fixed header (`--sitf-header-h`).
// The header was a hardcoded `4rem` in chrome.css until the admin bar turned out to be **69px** - a 44px
// trigger inside `py-3` - which put its bottom border 5px over the top of the sidebar. Reported as "an
// odd line that goes past the top nav, and the horizontal line does not continue". The padding is gone,
// but a header can still legitimately grow: it wraps at narrow widths, and at 200% text everything in it
// is bigger.
//
// A ResizeObserver rather than a resize listener: the height changes on rewrap, on zoom and on the
// webfont swap, and only the element knows about all three.
export default class extends Controller {
  static values = { variable: String }

  connect() {
    this.publish()
    this.observer = new ResizeObserver(() => this.publish())
    this.observer.observe(this.element)
  }

  disconnect() {
    this.observer?.disconnect()
    // Clearing rather than zeroing: the fallback in chrome.css is the right value for "no such element",
    // and for the header that is 4rem, not 0.
    document.documentElement.style.removeProperty(this.variableValue)
  }

  // `clientHeight`, not the bounding rect: it excludes the border, and the border is the seam. The two
  // headers carry `border-b` on different boxes - the app side on the `<header>` itself, admin on its
  // outer wrapper - so measuring the border box published 65 in one layout and 64 in the other, and the
  // sidebar aligned with one of them. This is the number the content sits at; the hairline then paints
  // on the line, which is what it has always done.
  publish() {
    document.documentElement.style.setProperty(this.variableValue, `${this.element.clientHeight}px`)
  }
}
