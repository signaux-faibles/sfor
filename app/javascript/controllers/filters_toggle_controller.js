import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["hiddenFilters", "toggleButton", "filtersOpenInput"];

    toggle() {
        console.log("Toggling")
        const isHidden = this.hiddenFiltersTarget.style.display === "none";

        this.hiddenFiltersTarget.style.display = isHidden ? "block" : "none";

        this.toggleButtonTarget.innerHTML = isHidden
            ? `<span class="fr-icon-arrow-up-line" aria-hidden="true"></span> Réduire les critères supplémentaires`
            : `<span class="fr-icon-arrow-down-line" aria-hidden="true"></span> Afficher des critères supplémentaires`;

        this.filtersOpenInputTarget.value = isHidden ? "true" : "false";
    }
}