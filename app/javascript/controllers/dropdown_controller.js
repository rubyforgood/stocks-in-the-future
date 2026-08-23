import { Controller } from "@hotwired/stimulus"

// Enhances a native <details>/<summary> menu: closes on outside click and on Escape,
// returning focus to the summary. Without JS the native disclosure still opens and
// closes, which is why the markup is <details> rather than a div plus a hidden panel.
//
// Deliberately not an ARIA menu widget with arrow-key roving. design.md: keep menus a
// disclosure of links unless a screen genuinely needs roving focus.
export default class extends Controller {
  connect() {
    this._onDocumentClick = (event) => {
      if (!this.element.open) return
      if (this.element.contains(event.target)) return
      this.close()
    }

    this._onKeydown = (event) => {
      if (event.key !== "Escape" || !this.element.open) return
      this.close()
    }

    document.addEventListener("click", this._onDocumentClick)
    document.addEventListener("keydown", this._onKeydown)
  }

  disconnect() {
    document.removeEventListener("click", this._onDocumentClick)
    document.removeEventListener("keydown", this._onKeydown)
  }

  close() {
    this.element.open = false

    // Focus goes back to the trigger rather than being dropped on the body, so keyboard
    // and screen reader users do not lose their place in the header.
    const summary = this.element.querySelector("summary")
    if (summary) summary.focus()
  }
}
