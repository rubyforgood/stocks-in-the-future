import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="submit-on-change"
//
// Submits the form as soon as a control inside it changes. The classroom trading switch did this
// with an inline `onchange="this.form.requestSubmit()"`, which was the last inline handler left in
// the app - every other interaction is a Stimulus action, and an inline handler is also the thing a
// Content-Security-Policy without 'unsafe-inline' blocks outright.
export default class extends Controller {
  submit(event) {
    const form = event.target.form || this.element.closest("form") || this.element

    if (form instanceof HTMLFormElement) form.requestSubmit()
  }
}
