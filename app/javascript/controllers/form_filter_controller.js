import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form-filter"
export default class extends Controller {
  static values = {
    frameId: String
  }

  change(event) {
    const value = event.target.value
    const frame = document.getElementById(this.frameIdValue)

    if (frame) {
      const url = new URL(frame.src || window.location.href)
      url.searchParams.set(event.target.name, value)
      frame.src = url.toString()
    }
  }
}
