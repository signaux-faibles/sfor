import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  connect() {
    this.openModal();
  }

  openModal() {
    dsfr(this.modalTarget).modal.disclose();
  }

  closeModal() {
    // @TODO : here, save date.
    dsfr(this.modalTarget).modal.conceal();
  }


}