import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]
  static values = { shouldShow: Boolean }

  connect() {
    if (this.shouldShowValue) {
      this.openModal();
    }
  }

  openModal() {
    dsfr(this.modalTarget).modal.disclose();
  }

  async closeModal() {
    // Save the acknowledgment timestamp
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
    
    try {
      const response = await fetch('/users/acknowledge_confidentiality', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        credentials: 'same-origin'
      });

      if (response.ok) {
        dsfr(this.modalTarget).modal.conceal();
      } else {
        console.error('Failed to save confidentiality acknowledgment');
      }
    } catch (error) {
      console.error('Error saving confidentiality acknowledgment:', error);
    }
  }
}