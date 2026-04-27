import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["body", "icon"];

    sort({ params: { column } }) {
        const rows = Array.from(this.bodyTarget.rows);
        const ascending = this.element.dataset.sortDirection !== "asc";
        this.element.dataset.sortDirection = ascending ? "asc" : "desc";

        if (this.hasIconTarget) {
            this.iconTarget.className = ascending ? "fr-icon-arrow-up-s-fill" : "fr-icon-arrow-down-s-fill";
        }

        rows.sort((a, b) => {
            const aVal = a.cells[column]?.dataset.sortValue ?? "";
            const bVal = b.cells[column]?.dataset.sortValue ?? "";
            if (aVal === "" && bVal === "") return 0;
            if (aVal === "") return 1;
            if (bVal === "") return -1;
            return ascending ? aVal.localeCompare(bVal) : bVal.localeCompare(aVal);
        });

        rows.forEach(row => this.bodyTarget.appendChild(row));
    }
}
