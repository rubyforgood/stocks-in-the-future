import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="autosave"
export default class extends Controller {
  static values = {
    interval: { type: Number, default: 30000 } // we'll default to 30 seconds here
  }

  static targets = ["form", "button", "status"]

  connect() {
    this.startAutosave()
    this.bindTurboEvents()
  }

  disconnect() {
    this.stopAutosave()
  }

  startAutosave() {
    this.timer = setInterval(() => this.save(), this.intervalValue)
  }

  stopAutosave() {
    if (this.timer) clearInterval(this.timer)
  }

  save() {
    if (!this.hasButtonTarget) return
    this.buttonTarget.click()
  }

  bindTurboEvents() {
      this.formTarget.addEventListener("turbo:submit-start", () => {
          this.buttonTarget.textContent = "Saving..."
      })
    this.formTarget.addEventListener("turbo:submit-end", () => {
      const now = new Date()
      const formatted = now.toLocaleTimeString([], {
        hour: "2-digit",
        minute: "2-digit",
        hour12: true
      })
      this.statusTarget.textContent = `Last saved at ${formatted}`
      this.buttonTarget.textContent = "Save Grades"
    })
  }
}
