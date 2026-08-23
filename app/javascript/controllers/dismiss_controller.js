import { Controller } from "@hotwired/stimulus"

// Removes the banner it is attached to, when the reader asks. Separate from `auto-dismiss` on
// purpose: a timer and a button are different promises, and two of the four banner types want one
// without the other.
//
//   flash notice   both - it auto-hides after 6s, and can be closed sooner
//   flash alert    this only - it never times out, because an error is often the only record of
//                  what went wrong, but the reader may still clear it once read
//   callout        never this one, even when dismissible. It is page state, and a dismissal that is
//                 not remembered comes back on the next page load, which reads as broken. A
//                 dismissible callout posts to `dismissals` instead - a button_to, not a controller.
//   error summary  neither. It describes the current state of the form and is rebuilt on submit;
//                 hiding it would hide the list of what still needs fixing.
//
// No fade here. The reader asked for it gone, and animating a departure they requested only delays
// it - which is also why this does not reuse auto-dismiss's transition.
export default class extends Controller {
  now() {
    this.element.remove()
  }
}
