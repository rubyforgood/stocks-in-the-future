import { Controller } from "@hotwired/stimulus"

// Makes a field read-only while another field's value means it will be derived rather than typed.
//
// Written for one case, and it is a case of the rule design.md already states: **a field whose value is
// silently discarded looks like a save that worked.** On `admin/users`, `Teacher#sync_username_from_email`
// runs `before_validation` and sets `username = email`, so a username typed for a teacher is thrown away on
// save - measured in a console, "typed_by_hand" came back as the email address. The form accepted it, said
// nothing, and the record disagreed with what had been typed.
//
// **Read-only, not disabled.** A disabled field is skipped by keyboard navigation, so the value a reader
// wants to see becomes unreachable - the profile page's username field records the same decision. Read-only
// keeps it focusable and copyable, and it is not submitted-but-ignored: it is submitted and then overwritten,
// which is exactly what the note says.
export default class extends Controller {
  static targets = ["source", "field", "note"]
  static values = { when: String }

  connect() {
    this.refresh()
  }

  refresh() {
    const derived = this.sourceTarget.value === this.whenValue

    this.fieldTarget.readOnly = derived
    this.fieldTarget.classList.toggle("bg-slate-50", derived)
    this.fieldTarget.classList.toggle("text-slate-600", derived)

    if (this.hasNoteTarget) this.noteTarget.hidden = !derived
  }
}
