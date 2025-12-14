// app/javascript/controllers/detection_widget_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["usefulDetection"]

  handleUselessDetection(event) {
    event.preventDefault()

    const form = event.target
    const formData = new FormData(form)

    // Get form data.
    const checkedReasons = []
    for (let [key, value] of formData.entries()) {
      if (key.startsWith('raisons-')) {
        const label = form.querySelector(`label[for="${key}"]`)
        checkedReasons.push(label.textContent.trim())
      }
    }

    // Check if at least one reason is checked.
    if (checkedReasons.length === 0) {
      const messagesGroup = form.querySelector('#raisons-messages')
      messagesGroup.innerHTML = `
      <p class="fr-message fr-message--error">Vous devez cocher au moins une raison.</p>
    `
      const firstCheckbox = form.querySelector('#raisons-1')
      firstCheckbox.focus()

      return // If not, stop here.
    }

    const precisions = formData.get('precisions') || ''

    // @Todo : save data.

    if (true) {
      this.showSuccess()
    } else {
      this.showError()
    }

    // Close modale.
    const modal = document.querySelector('#modal-feedback-detection')
    window.dsfr(modal).modal.conceal()
  }

  handleUsefulDetection(event) {
    event.preventDefault()
    // @Todo : save data.

    if (true) {
      this.showSuccess()
    } else {
      this.showError()
    }
  }

  showSuccess() {
    // Display success message.
    const successAlert = document.createElement('div')
    successAlert.className = 'fr-alert fr-alert--success fr-alert--sm fr-mb-3w'
    successAlert.innerHTML = '<p>Merci pour votre retour</p>'

    this.element.insertAdjacentElement('afterbegin', successAlert)

    // Hide buttons.
    const buttons = this.element.querySelectorAll('.sf-feedback-detection-button')
    buttons.forEach(button => button.style.display = 'none')
  }

  showError() {
    // Display error message.
    const errorAlert = document.createElement('div')
    errorAlert.className = 'fr-alert fr-alert--error fr-alert--sm fr-mb-3w'
    errorAlert.innerHTML = '<p>Une erreur est survenue. Veuillez réessayer.</p>'

    this.element.insertAdjacentElement('afterbegin', errorAlert)
  }
}