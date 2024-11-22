import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["hiddenFilters", "toggleButton", "filtersOpenInput"];

    toggle() {
        console.log("Toggling")
        const isHidden = this.hiddenFiltersTarget.style.display === "none";

        // Toggle hidden filters visibility
        this.hiddenFiltersTarget.style.display = isHidden ? "block" : "none";

        // Update the button's icon and label dynamically
        this.toggleButtonTarget.innerHTML = isHidden
            ? `<span class="fr-icon-arrow-up-line" aria-hidden="true"></span> Réduire les critères supplémentaires`
            : `<span class="fr-icon-arrow-down-line" aria-hidden="true"></span> Afficher des critères supplémentaires`;

        // Update the hidden input field value
        this.filtersOpenInputTarget.value = isHidden ? "true" : "false";
    }
}