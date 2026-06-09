import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  load(event) {
    event.preventDefault()

    const countBefore = document.querySelectorAll("#companies-container [data-company-id]").length

    fetch(this.urlValue, {
      headers: { Accept: "text/vnd.turbo-stream.html" }
    })
      .then((response) => {
        if (!response.ok) throw new Error(`Load more failed: ${response.status}`)
        return response.text()
      })
      .then((html) => {
        window.Turbo.renderStreamMessage(html)
        this.focusFirstNewCompany(countBefore)
      })
      .catch((error) => console.error(error))
  }

  focusFirstNewCompany(countBefore) {
    const cards = document.querySelectorAll("#companies-container [data-company-id]")
    if (cards.length <= countBefore) return

    const firstNewCard = cards[countBefore]
    const link = firstNewCard.querySelector(".fr-card__title a") || firstNewCard.querySelector("a")
    link?.focus()
  }
}
