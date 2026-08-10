import { Controller } from "@hotwired/stimulus"

// Autosave for the grade book.
//
// **Why on blur, not only on a timer.** Finalizing pays whatever is in the database, so anything typed
// and not yet saved is money that will not be paid. With a 30-second interval as the only trigger there
// was a window in which a teacher could enter a grade, press Finalize, and pay the previous one - and
// nothing on the page said so. Saving when a field loses focus closes that window at the root: by the
// time a hand reaches Finalize, whatever it typed has already gone.
//
// The interval stays as a backstop for a field left focused - somebody typing in the last cell and
// walking away never blurs it.
export default class extends Controller {
  static values = {
    interval: { type: Number, default: 30000 }
  }

  static targets = ["form", "button", "status"]

  connect() {
    this.startAutosave()
    this.bindTurboEvents()
    this.bindBlur()
    this.showSaved()
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

  // A capturing listener on the form, because `blur` does not bubble. `focusout` does, but this also
  // fires for a radio being moved through with the keyboard, so the save is skipped when nothing changed.
  bindBlur() {
    this.formTarget.addEventListener("change", () => { this.dirty = true })
    this.formTarget.addEventListener(
      "blur",
      () => { if (this.dirty) this.save() },
      true
    )
  }

  save() {
    if (!this.hasButtonTarget) return
    this.dirty = false
    this.buttonTarget.click()
  }

  // The save state, in words, next to the button that does it. It used to be blank until the first save,
  // so a page you had not touched yet said nothing about whether it was safe to finalize - and "nothing"
  // is exactly what an unsaved page looks like too.
  showSaved(at) {
    if (!this.hasStatusTarget) return

    this.statusTarget.textContent = at ? `All changes saved · ${at}` : "All changes saved"
  }

  bindTurboEvents() {
    this.formTarget.addEventListener("turbo:submit-start", () => {
      if (this.hasStatusTarget) this.statusTarget.textContent = "Saving…"
    })

    this.formTarget.addEventListener("turbo:submit-end", () => {
      const now = new Date()
      this.showSaved(now.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }))
    })
  }
}
