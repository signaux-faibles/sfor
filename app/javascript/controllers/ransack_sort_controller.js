import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { url: String };

  sort() {
    document.addEventListener("turbo:frame-load", () => {
      document.querySelector('[data-controller="ransack-sort"]')?.focus();
    }, { once: true });
    history.pushState({}, "", this.urlValue);
    document.getElementById("sort-results").src = this.urlValue;
  }
}
