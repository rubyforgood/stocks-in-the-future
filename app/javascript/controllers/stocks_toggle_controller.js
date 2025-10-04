import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  navigateLink(event) {
    // Prevent the summary from toggling when clicking the link
    event.stopPropagation()
    // Let the link navigate normally
  }
}
