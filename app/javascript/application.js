// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

import "trix"
import "@rails/actiontext"

// Native HTML5 validation is off app-wide, which is what lets the app's own validation errors show at
// all. design.md: "otherwise the browser's native bubbles (required, type, min) fire first, block the
// submit, and can't be styled" - so a blank required field never reached the server and neither the
// error summary nor the field-level messages could ever render. The one test in the suite that needed
// the summary had to submit a *duplicate* username to get past the browser.
//
// The inputs keep `required`: it is what tells assistive tech the field is required, and it is harmless
// once the browser is not acting on it.
//
// Opt a form back in with `data-native-validation`.
//
// Re-applied on turbo:load and turbo:frame-load as well as the initial parse, because Turbo Drive
// replaces the body on navigation and a frame can bring a new form in on its own.
const disableNativeValidation = () => {
  document.querySelectorAll("form:not([data-native-validation])").forEach((form) => {
    form.noValidate = true
  })
}

document.addEventListener("DOMContentLoaded", disableNativeValidation)
document.addEventListener("turbo:load", disableNativeValidation)
document.addEventListener("turbo:frame-load", disableNativeValidation)
document.addEventListener("turbo:render", disableNativeValidation)
