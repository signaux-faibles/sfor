import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["hiddenInput", "tableView", "cardsView", "pagination"];

    connect() {
        const currentView = this.hiddenInputTarget.value;
        this.switchView(currentView);
        // We need to include the selected view dynamically into pagination request
        this.updatePaginationLinks(currentView);
    }

    change(event) {
        const selectedView = event.target.value;
        this.updateHiddenInput(selectedView);
        this.switchView(selectedView);
        this.updatePaginationLinks(selectedView);
    }

    updateHiddenInput(view) {
        if (this.hasHiddenInputTarget) {
            this.hiddenInputTarget.value = view;
        }
    }

    switchView(view) {
        // Only try to switch views if both targets exist
        if (this.hasCardsViewTarget && this.hasTableViewTarget) {
            if (view === "cards") {
                this.cardsViewTarget.style.display = "flex";
                this.tableViewTarget.style.display = "none";
            } else {
                this.cardsViewTarget.style.display = "none";
                this.tableViewTarget.style.display = "block";
            }
        }
    }

    updatePaginationLinks(view) {
        if (!this.hasPaginationTarget) return;

        this.paginationTarget.querySelectorAll("a").forEach((link) => {
            const href = link.getAttribute("href");
            if (!href) return;

            const url = new URL(href, window.location.origin);
            url.searchParams.set("q[view]", view);
            link.setAttribute("href", url.toString());
        });
    }
}