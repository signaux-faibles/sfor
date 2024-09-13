import { Controller } from "@hotwired/stimulus"

// Tom Select est déjà  chargé globalement par Importmap

export default class extends Controller {
    connect() {
        new TomSelect(this.element, {
            plugins: ['remove_button'],
            maxOptions: null,
            create: false,
            sortField: {
                field: "text",
                direction: "asc"
            }
        });
    }
}