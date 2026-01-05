import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="feedback-detection"
export default class extends Controller {
  static targets = ["reasonCheckbox", "errorMessage", "reasonsContainer", "submitButton"]

  validateForm(event) {
    const checkedBoxes = this.reasonCheckboxTargets.filter(checkbox => checkbox.checked)

    if (checkedBoxes.length === 0) {
      event.preventDefault()
      this.showError("Vous devez cocher au moins une raison.")
      return false
    }

    this.hideError()
    return true
  }

  showError(message) {
    const errorContainer = this.errorMessageTarget
    errorContainer.innerHTML = `<p class="fr-message fr-message--error">${message}</p>`
    errorContainer.setAttribute("aria-live", "polite")
    
    // Focus on first checkbox for accessibility
    if (this.reasonCheckboxTargets.length > 0) {
      this.reasonCheckboxTargets[0].focus()
    }
  }

  hideError() {
    const errorContainer = this.errorMessageTarget
    errorContainer.innerHTML = ""
  }
}

