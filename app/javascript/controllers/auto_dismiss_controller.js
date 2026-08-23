import { Controller } from "@hotwired/stimulus"

// Clears a transient success message after a delay. Connected only to the flash `notice`.
//
// **Success auto-hides, errors stay.** An error is often the only record of what went wrong, and
// `#alert` carries `role="alert"` - an interrupting semantic - so it is never given this controller.
// Nor are callouts: `components/ui/_callout` is page state ("trading is closed"), not the outcome of
// something you just did, and state that removes itself is a lie about the page. The same goes for
// the form error summaries on students#new, students#edit and profiles.
//
// 6s, per design.md. The field runs 3-10s and clusters at 4-6 - Polaris, Bootstrap and Chakra all
// default to 5s, Material to 4s, Ant to 3s - and the long end of that band suits readers who are
// eleven.
//
// Hovering or focusing holds it, so it cannot vanish mid-read: that plus a delay well above a
// couple of seconds is what keeps an auto-hiding status message clear of WCAG 2.2.1. Leaving
// restarts the full delay rather than resuming the remainder, which is what Polaris does and means
// a message you have just looked away from still gets its whole life on screen.
const AFTER_MS = 6000
const FADE_MS = 300
const REDUCED_MOTION = "(prefers-reduced-motion: reduce)"

export default class extends Controller {
  static values = { after: { type: Number, default: AFTER_MS } }

  connect() {
    this.start()
  }

  // A Turbo visit tears the element out from under a pending timer, and a timer holding a detached
  // node would keep it alive and then throw on remove().
  disconnect() {
    this._cancel()
  }

  start() {
    this._cancel()
    this.timer = setTimeout(() => this.dismiss(), this.afterValue)
  }

  hold() {
    this._cancel()
  }

  dismiss() {
    this._cancel()

    // The fade is an inline style, not a utility class: Tailwind only emits the classes it can see
    // in the templates, so an `opacity-0` added from JS is not guaranteed to exist in the build.
    //
    // Removal is on its own timer rather than `transitionend`, because a transition that never
    // fires - a display change mid-fade, a browser that skips it under reduced motion - would leave
    // the message on screen forever.
    if (this._prefersReducedMotion) {
      this.element.remove()
      return
    }

    this.element.style.transition = `opacity ${FADE_MS}ms`
    this.element.style.opacity = "0"
    this.removal = setTimeout(() => this.element.remove(), FADE_MS)
  }

  get _prefersReducedMotion() {
    return window.matchMedia(REDUCED_MOTION).matches
  }

  _cancel() {
    if (this.timer) clearTimeout(this.timer)
    if (this.removal) clearTimeout(this.removal)
    this.timer = null
    this.removal = null
  }
}
