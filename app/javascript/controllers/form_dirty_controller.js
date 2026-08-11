import { Controller } from "@hotwired/stimulus"

// Marks a form as having unsaved changes, so its action row can pin itself only once there is something to
// save. See `.tw-form-actions` in forms.css for why that is conditional.
//
// One controller on <body> rather than an attribute on eleven forms: `input` and `change` bubble, so a single
// listener sees every field in the document, and a form added by Turbo needs no wiring.
//
// It does not un-dirty when a value is put back to what it was. Polaris tracks that; doing it here would mean
// snapshotting every field on connect and comparing on each keystroke, and the cost of being wrong is a save
// button offered when nothing needs saving - which is the state the whole app was in a commit ago.
export default class extends Controller {
  connect() {
    this.mark = this.mark.bind(this)
    document.addEventListener("input", this.mark)
    document.addEventListener("change", this.mark)
  }

  disconnect() {
    document.removeEventListener("input", this.mark)
    document.removeEventListener("change", this.mark)
  }

  mark(event) {
    const form = event.target.closest?.("form")

    // A form whose submit is its own action - `button_to` renders one per row - has nothing to pin, and
    // marking it would pin an action row belonging to a different form on the same page.
    if (!form || !form.querySelector(".tw-form-actions")) return

    form.dataset.formDirty = "true"
  }
}
