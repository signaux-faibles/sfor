import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["stateSelect", "warningBanner"]
  static values = {
    initialState: String
  }

  connect() {
    this.initialStateValue = this.stateSelectTarget.value
    this.toggleWarningBanner()
  }

  toggleWarningBanner() {
    const isCompleted = this.initialStateValue === 'completed'
    const isChangingFromCompleted = isCompleted && this.stateSelectTarget.value !== 'completed'
    
    if (isChangingFromCompleted) {
      this.warningBannerTarget.classList.remove('fr-hidden')
    } else {
      this.warningBannerTarget.classList.add('fr-hidden')
    }
  }

  stateSelectTargetConnected(element) {
    this.toggleWarningBanner()
  }
} 