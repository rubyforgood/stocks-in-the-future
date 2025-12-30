import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="admin-sidebar"
export default class extends Controller {
  static targets = ["mobileSidebar", "overlay"]

  toggle() {
    this.mobileSidebarTarget.classList.toggle("-translate-x-full")

    // Toggle overlay visibility
    if (this.overlayTarget.classList.contains("hidden")) {
      this.overlayTarget.classList.remove("hidden")
      this.overlayTarget.style.display = "block"
    } else {
      this.overlayTarget.classList.add("hidden")
      this.overlayTarget.style.display = "none"
    }
  }
}
