import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  navigateLink(event) {
    // Prevent the summary from toggling when clicking the link
    event.stopPropagation()

    // Close the mobile menu by unchecking the checkbox
    const menuCheckbox = document.getElementById('mobile-menu-toggle')
    if (menuCheckbox) {
      menuCheckbox.checked = false
    }
  }

  toggleChevron(event) {
    event.preventDefault()
    event.stopPropagation()
    this.element.open = !this.element.open
  }
}
