import { Controller } from "@hotwired/stimulus"

// Provides an accessible custom validity message for HTML5 email format checks.
export default class extends Controller {
  static values = { invalidMessage: String }

  connect() {
    this.clearValidity = this.clearValidity.bind(this)
    this.showValidity = this.showValidity.bind(this)
    this.element.addEventListener("input", this.clearValidity)
    this.element.addEventListener("invalid", this.showValidity)
  }

  disconnect() {
    this.element.removeEventListener("input", this.clearValidity)
    this.element.removeEventListener("invalid", this.showValidity)
  }

  clearValidity() {
    this.element.setCustomValidity("")
  }

  showValidity() {
    if (this.hasInvalidMessageValue) {
      this.element.setCustomValidity(this.invalidMessageValue)
    }
  }
}
