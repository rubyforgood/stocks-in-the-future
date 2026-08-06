import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Replaces the browser's native confirm() for every `data-turbo-confirm` in the app.
//
// There are 28 of them, on links, `button_to` forms and helper-generated row actions - including the
// one that finalizes a grade book and deposits real money into every student's portfolio. All of them
// were an unstyled OS dialog whose buttons said "OK" and "Cancel", which is the one surface in the
// product that could not be designed.
//
// Registered globally rather than per call site, which is the only way to cover 28 of them without
// touching any: Turbo reads `config.forms.confirm` in FormSubmission#start, and a link carrying
// `turbo_method` becomes a form submission, so links are covered too.
//
// `Turbo.config.forms.confirm`, not `Turbo.setConfirmMethod`: the latter is deprecated in turbo-rails
// 2.0.23 and warns to the console. Turbo calls it with (message, formElement, submitter), and the
// submitter is what lets the accept button carry the verb from the control that was pressed rather
// than saying "OK".
//
// If this controller never connects - a JS failure, an old browser - `config.forms.confirm` stays unset
// and Turbo falls back to native confirm(). The confirmation still happens; it is just ugly. A
// destructive action must never lose its confirmation because a stylesheet did not load.
const MAX_VERB = 32

export default class extends Controller {
  static targets = ["message", "accept"]

  connect() {
    Turbo.config.forms.confirm = (message, _form, submitter) => this._ask(message, submitter)
  }

  // Handing it back rather than leaving a dangling reference to a removed element. A Turbo visit
  // replaces the body, so this controller disconnects and reconnects on every navigation.
  disconnect() {
    Turbo.config.forms.confirm = null
    this._settle()
  }

  accept() {
    this._answer = true
    this.element.close()
  }

  cancel() {
    this._answer = false
    this.element.close()
  }

  // Every path out of the dialog ends in the native `close` event - the two buttons, Escape, and the
  // backdrop click below - so the promise is settled in exactly one place and cannot be left hanging.
  // An unanswered dialog resolves false: dismissing a confirmation is declining it.
  closed() {
    this._settle()
  }

  // A native <dialog> does not close on a backdrop click, and the backdrop is the dialog element itself:
  // a click whose target is the dialog rather than anything inside it landed outside the panel.
  backdrop(event) {
    if (event.target === this.element) this.cancel()
  }

  _ask(message, submitter) {
    this.messageTarget.textContent = message
    this.acceptTarget.textContent = this._verb(submitter)

    return new Promise((resolve) => {
      this._resolve = resolve
      this._answer = false
      this.element.showModal()
    })
  }

  // The label of the control that was pressed - "Finalize grades", "Delete student" - so the accept
  // button names the action it is about to take. GitHub, Stripe and Polaris all label a confirm with the
  // verb rather than with "OK", because "OK" makes the reader re-read the question to know what it does.
  _verb(submitter) {
    const label = (submitter?.value || submitter?.textContent || "").replace(/\s+/g, " ").trim()

    return label && label.length <= MAX_VERB ? label : "Confirm"
  }

  _settle() {
    const resolve = this._resolve
    this._resolve = null
    if (resolve) resolve(this._answer === true)
    this._answer = false
  }
}
