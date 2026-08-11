import { Controller } from "@hotwired/stimulus"

// Hides a form's action row until there is something to save, then pins it. See `.tw-form-actions` in
// forms.css for why both halves are conditional.
//
// One controller on <body> rather than an attribute on eleven forms: `input` and `change` bubble, so a single
// listener sees every field in the document, and a form that arrives with a Turbo response needs no wiring.
//
// It does not un-hide when a value is put back to what it was. Polaris tracks that; doing it here would mean
// snapshotting every field on connect and comparing on each keystroke, and the cost of being wrong is a save
// offered when nothing needs saving - which is the state this replaced.
export default class extends Controller {
  connect() {
    this.mark = this.mark.bind(this)
    this.hideCleanForms = this.hideCleanForms.bind(this)

    document.addEventListener("input", this.mark)
    document.addEventListener("change", this.mark)

    this.hideCleanForms()
    // Turbo swaps the body without reconnecting a body-level controller, so a page arriving by navigation
    // needs the pass running again.
    document.addEventListener("turbo:load", this.hideCleanForms)
    document.addEventListener("turbo:frame-load", this.hideCleanForms)
  }

  disconnect() {
    document.removeEventListener("input", this.mark)
    document.removeEventListener("change", this.mark)
    document.removeEventListener("turbo:load", this.hideCleanForms)
    document.removeEventListener("turbo:frame-load", this.hideCleanForms)
  }

  // Only a form that *updates* something starts hidden. A create form has nothing saved to compare against,
  // and its submit is the only way to do anything at all.
  hideCleanForms() {
    document.querySelectorAll("form").forEach((form) => {
      if (!form.querySelector(".tw-form-actions")) return
      if (form.dataset.formDirty === "true") return
      if (!this.updates(form)) return

      form.dataset.formClean = "true"
    })
  }

  // Rails posts an update through a hidden `_method`, so the markup says which this is without a local.
  updates(form) {
    const method = form.querySelector("input[name='_method']")

    return method !== null && ["patch", "put"].includes(method.value.toLowerCase())
  }

  mark(event) {
    const form = event.target.closest?.("form")

    // A form whose submit is its own action - `button_to` renders one per row - has no action row to reveal,
    // and marking it would pin one belonging to a different form on the same page.
    if (!form || !form.querySelector(".tw-form-actions")) return

    delete form.dataset.formClean
    form.dataset.formDirty = "true"
  }
}
