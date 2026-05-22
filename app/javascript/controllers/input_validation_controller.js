import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener("invalid", this.#onInvalid)
    this.element.addEventListener("input", this.#onInput)
  }

  disconnect() {
    this.element.removeEventListener("invalid", this.#onInvalid)
    this.element.removeEventListener("input", this.#onInput)
  }

  #onInvalid = (event) => {
    const message = this.element.dataset.invalidMessage
    if (message) event.target.setCustomValidity(message)
  }

  #onInput = () => {
    this.element.setCustomValidity("")
  }
}
