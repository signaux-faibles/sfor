import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.showModal()
  }

  async closeModal() {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")

    const response = await fetch("/users/acknowledge_confidentiality", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken
      },
      credentials: "same-origin"
    })

    if (response.ok) {
      this.element.close()
    }
  }
}
