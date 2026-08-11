import { Controller } from "@hotwired/stimulus"

// Marks a table whose actions cell is actually pinned, so it can take an opaque ground and a
// separator - and only then.
//
// **The condition is "can scroll", not "has scrolled", and getting that wrong was a reported bug:**
// "the buttons overlap over the columns to the left when the viewport size is reduced". A
// `sticky right-0` cell is pulled into view the moment its table is wider than its container, which
// is at scroll position **0** - before any scroll event exists to react to. So the cell floated over
// the columns beneath it with no background, because the flag it depended on was only ever set by a
// scroll listener.
//
// It still must not fire on a table that fits. Unconditional below `lg` was the original bug: the
// student portfolio's holdings table never scrolls at any width - it adapts by wrapping the company
// name - so that drew a stray rule beside the Trade button and put an opaque cell over the row's
// hover tint, for no scroll.
//
// One controller on <body> rather than an attribute on all eleven wrappers. Scroll events do not
// bubble but do fire in the capture phase, so one capturing listener sees every scroll; overflow needs
// polling of a different kind, and a ResizeObserver on each container gives it without a timer.
export default class extends Controller {
  connect() {
    this.onScroll = this.onScroll.bind(this)
    document.addEventListener("scroll", this.onScroll, true)

    this.observer = new ResizeObserver(() => this.markAll())
    this.watch()

    // Turbo replaces the body's contents without reconnecting this controller, so a table that
    // arrives with a frame or a stream needs picking up.
    this.onLoad = () => this.watch()
    document.addEventListener("turbo:load", this.onLoad)
    document.addEventListener("turbo:frame-load", this.onLoad)
    document.addEventListener("turbo:before-stream-render", this.onLoad)
  }

  disconnect() {
    document.removeEventListener("scroll", this.onScroll, true)
    document.removeEventListener("turbo:load", this.onLoad)
    document.removeEventListener("turbo:frame-load", this.onLoad)
    document.removeEventListener("turbo:before-stream-render", this.onLoad)
    this.observer?.disconnect()
  }

  // Observing the container *and* its table: the container's box changes with the viewport, and the
  // table's changes when its content does, and either can flip whether it overflows.
  watch() {
    this.markAll()
    this.containers().forEach((el) => {
      this.observer.observe(el)
      if (el.firstElementChild) this.observer.observe(el.firstElementChild)
    })
  }

  containers() {
    return [...document.querySelectorAll("[class*='overflow-x']")].filter((el) => {
      const overflow = getComputedStyle(el).overflowX
      return overflow === "auto" || overflow === "scroll"
    })
  }

  markAll() {
    this.containers().forEach((el) => this.mark(el))
  }

  // A string, not a boolean: the CSS selector matches on the value.
  mark(el) {
    el.dataset.tablePinned = el.scrollWidth > el.clientWidth + 1 ? "true" : "false"
  }

  onScroll(event) {
    const el = event.target
    if (!(el instanceof Element)) return

    const overflow = getComputedStyle(el).overflowX
    if (overflow !== "auto" && overflow !== "scroll") return

    this.mark(el)
  }
}
