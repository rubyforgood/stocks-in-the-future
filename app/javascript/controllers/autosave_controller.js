import { Controller } from "@hotwired/stimulus"

// Autosave for the grade book.
//
// **Why on blur, not only on a timer.** Finalizing pays whatever is in the database, so anything typed
// and not yet saved is money that will not be paid. With a 30-second interval as the only trigger there
// was a window in which a teacher could enter a grade, press Finalize, and pay the previous one - and
// nothing on the page said so. Saving when a field loses focus closes that window at the root.
//
// The interval stays as a backstop for a field left focused: somebody typing in the last cell and
// walking away never blurs it.
//
// **Why the status line barely moves.** Measured, it used to change three times per edit - "Saving…",
// "All changes saved", then a new timestamp - which on a 25-student book is about three hundred redraws
// in one spot while a teacher works. Docs, Notion and Figma all keep the steady state quiet and
// unchanging; none of them counts saves at the user. So:
//
//   - no timestamp, ever: "when" is not the question a teacher is asking, and it was the churn;
//   - "Saving…" only if a save is still running after PENDING_AFTER_MS, so an ordinary edit changes
//     nothing on screen at all;
//   - a failure says so and **stays**, which is the one state a teacher has to act on and the one thing
//     this never handled.
const PENDING_AFTER_MS = 800

export default class extends Controller {
  static values = {
    interval: { type: Number, default: 30000 }
  }

  static targets = ["form", "button", "status"]

  connect() {
    this.startAutosave()
    this.bindTurboEvents()
    this.bindBlur()
    this.setStatus("All changes saved")
  }

  disconnect() {
    this.stopAutosave()
    this.clearPendingTimer()
  }

  startAutosave() {
    this.timer = setInterval(() => this.save(), this.intervalValue)
  }

  stopAutosave() {
    if (this.timer) clearInterval(this.timer)
  }

  // A capturing listener, because `blur` does not bubble. The `change` flag stops a save firing for a
  // field somebody only tabbed through, which is most of them.
  bindBlur() {
    this.formTarget.addEventListener("change", () => { this.dirty = true })
    this.formTarget.addEventListener("blur", () => { if (this.dirty) this.save() }, true)
  }

  save() {
    if (!this.hasButtonTarget) return
    this.dirty = false
    this.buttonTarget.click()
  }

  // Assign only when the words actually change. Writing the same string still replaces the text node,
  // which is a mutation the eye can catch and a re-announcement for a screen reader on an aria-live
  // region.
  setStatus(text, failed = false) {
    if (!this.hasStatusTarget) return
    if (this.statusTarget.textContent === text) return

    this.statusTarget.textContent = text
    this.statusTarget.classList.toggle("text-red-700", failed)
    this.statusTarget.classList.toggle("font-medium", failed)
    this.statusTarget.classList.toggle("text-slate-600", !failed)
  }

  clearPendingTimer() {
    if (this.pendingTimer) clearTimeout(this.pendingTimer)
    this.pendingTimer = null
  }

  bindTurboEvents() {
    this.formTarget.addEventListener("turbo:submit-start", () => {
      this.clearPendingTimer()
      this.pendingTimer = setTimeout(() => this.setStatus("Saving…"), PENDING_AFTER_MS)
    })

    this.formTarget.addEventListener("turbo:submit-end", (event) => {
      this.clearPendingTimer()

      if (event.detail && event.detail.success === false) {
        this.setStatus("Not saved — check your connection", true)
      } else {
        this.setStatus("All changes saved")
      }
    })
  }
}
