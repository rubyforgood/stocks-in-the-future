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
// 2.0.23 and warns to the console. Turbo calls it with (message, formElement, submitter).
//
// The submitter is only there for a `button_to`. For a **link** carrying `turbo_method`, Turbo builds a
// throwaway form and copies exactly five attributes onto it - data-turbo-method, -frame, -action,
// -confirm, -stream - and passes no submitter at all (FormLinkClickObserver#followedLinkToLocation).
// That is why ~20 link-driven confirmations used to say "Confirm" instead of their verb, and why a
// second data attribute on the link cannot carry anything here.
//
// So the trigger is captured on the way in instead: one capturing click listener, remembering the
// nearest element carrying `data-turbo-confirm`. A confirmation always follows the activation that
// caused it - a keyboard Enter on a link fires a click too - so the element is the right one, and the
// accept button gets its verb and its destructive treatment from the control that was actually pressed.
//
// If this controller never connects - a JS failure, an old browser - `config.forms.confirm` stays unset
// and Turbo falls back to native confirm(). The confirmation still happens; it is just ugly. A
// destructive action must never lose its confirmation because a stylesheet did not load.
const MAX_VERB = 32

export default class extends Controller {
  static targets = ["message", "body", "accept"]

  connect() {
    this._trigger = null
    this._rememberTrigger = (event) => {
      const el = event.target?.closest?.("[data-turbo-confirm]")
      if (el) this._trigger = el
    }
    // Capturing, so it runs before Turbo's own click handling opens the dialog.
    document.addEventListener("click", this._rememberTrigger, true)

    Turbo.config.forms.confirm = (message, _form, submitter) => this._ask(message, submitter)
  }

  // Handing it back rather than leaving a dangling reference to a removed element. A Turbo visit
  // replaces the body, so this controller disconnects and reconnects on every navigation.
  disconnect() {
    document.removeEventListener("click", this._rememberTrigger, true)
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
    const [question, ...rest] = String(message).split(/\n\s*\n|\n/)
    const body = rest.join(" ").trim()

    this.messageTarget.textContent = question.trim()
    this.bodyTarget.textContent = body
    this.bodyTarget.classList.toggle("hidden", body === "")

    const trigger = submitter || this._trigger
    this.acceptTarget.textContent = this._verb(trigger)
    this._setDanger(this._destructive(trigger))

    return new Promise((resolve) => {
      this._resolve = resolve
      this._answer = false
      this.element.showModal()
    })
  }

  // The label of the control that was pressed - "Finalize grades", "Delete student" - so the accept
  // button names the action it is about to take. GitHub, Stripe and Polaris all label a confirm with the
  // verb rather than with "OK", because "OK" makes the reader re-read the question to know what it does.
  _verb(trigger) {
    const label = (trigger?.value || trigger?.textContent || "").replace(/\s+/g, " ").trim()

    return label && label.length <= MAX_VERB ? label : "Confirm"
  }

  // A control marks itself destructive, rather than this guessing from its words: matching on "delete"
  // or "remove" would colour a button red because of a noun in its label, and would miss "Deactivate".
  // `ghost_action_link variant: :danger` already carries the ghost's danger class, so both are accepted
  // and no call site has to repeat itself.
  _destructive(trigger) {
    if (!trigger) return false

    return trigger.hasAttribute("data-confirm-danger") ||
           trigger.className.toString().includes("hover:text-rose-700")
  }

  // `.tw-btn-danger` - solid rose - which design.md now names for exactly this and only this. The
  // "no red at rest" rule keeps its force for every control that sits on a page; a confirmation is not
  // sitting in wait, and the two answers to a destructive question should not be the same white box.
  //
  // Cancel keeps `autofocus` regardless, so the destructive answer is still not the default. That is
  // Apple HIG's rule and it is orthogonal to the fill; Polaris and Carbon ship both together.
  _setDanger(danger) {
    this.acceptTarget.classList.toggle("tw-btn-danger", danger)
    this.acceptTarget.classList.toggle("tw-btn-primary", !danger)
  }

  _settle() {
    const resolve = this._resolve
    this._resolve = null
    if (resolve) resolve(this._answer === true)
    this._answer = false
  }
}
