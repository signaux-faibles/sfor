import { Controller } from "@hotwired/stimulus"

// Moves keyboard focus to the start of the page on load (e.g. login notice before the form).
export default class extends Controller {
  connect() {
    if (this.element.tabIndex < 0) {
      this.element.tabIndex = -1
    }

    requestAnimationFrame(() => {
      this.element.focus({ preventScroll: true })
    })
  }
}
