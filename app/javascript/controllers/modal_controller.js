import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay"]

  connect() {
    this.boundShowModal = this._show.bind(this)
    document.addEventListener("turbo:frame-load", this.boundShowModal)
  }

  disconnect() {
    if (this.boundShowModal) {
      document.removeEventListener("turbo:frame-load", this.boundShowModal)
    }
  }

  _show(event) {
    const frame = event.target
    if (frame.id === "modal_frame" && frame.innerHTML.trim() !== "") {
      this.show()
    }
  }

  show() {
    this.overlayTarget.classList.remove("hidden")
  }

  close() {
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add("hidden")
      
      const frame = this.overlayTarget.querySelector("turbo-frame#modal_frame")
      if (frame) {
        frame.innerHTML = ""
      }
    }
  }
}