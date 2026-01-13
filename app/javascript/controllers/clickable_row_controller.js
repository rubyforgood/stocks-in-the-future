import { Controller } from "@hotwired/stimulus"
import { visit } from "@hotwired/turbo"

// Connects to data-controller="clickable-row"
export default class extends Controller {
  static values = {
    url: String
  }

  connect() {
    this.element.style.cursor = "pointer"
  }

  navigate(event) {
    // Don't navigate if clicking on a link, button, or interactive element
    const targetElement = event.target
    const isInteractiveElement = targetElement.closest("a, button, input, select, textarea")

    if (isInteractiveElement) {
      return
    }

    // Navigate to the show page
    if (this.urlValue) {
      visit(this.urlValue)
    }
  }
}
