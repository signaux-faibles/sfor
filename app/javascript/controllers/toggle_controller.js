import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["hiddenFilters"];

    toggle() {
        const isHidden = this.hiddenFiltersTarget.style.display === "none";
        this.hiddenFiltersTarget.style.display = isHidden ? "block" : "none";
    }
}