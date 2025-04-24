import { Controller } from "@hotwired/stimulus"

// Tom Select est déjà  chargé globalement par Importmap

export default class extends Controller {

    connect() {
        // Fix the issue of the tom-select instance not being initialized when hitting back button of the browser
        if (this.element.tomselect) {
            this.element.tomselect.destroy();
        }

        const minSearchAttr = this.element.dataset.minSearch;
        const threshold = minSearchAttr ? parseInt(minSearchAttr, 10) : 1;

        const options = {
            clearOnBlur: false,
            persist: true,
            closeAfterSelect: true,
            plugins: ['remove_button'],
            maxOptions: null,
            create: false,
            dropdownParent: 'body',
            openOnFocus: !minSearchAttr,
            hidePlaceholder: true,
            render: {
                option: function(data, escape) {
                    return `<div class="option" style="margin-left: 10px;">${escape(data.text)}</div>`;
                },
                item: function(data, escape) {
                    return `<div class="item">${escape(data.text)}</div>`;
                },
                optgroup_header: function(data, escape) {
                    return `<div class="optgroup-header" style="font-weight: bold;">${escape(data.label)}</div>`;
                },
                no_results: function(data, escape) {
                    return '<div class="no-results">' + 'Aucun résultat' + '</div>';
                }
            },

            onItemAdd: function(value, item) {
                this.setTextboxValue('');
                this.refreshOptions();
            },

            onType: function(str) {
                if (str.length >= threshold) {
                    this.refreshOptions(true);
                } else {
                    this.close();
                    this.setTextboxValue(str);
                }
            }
        }

        this.tomSelectInstance = new TomSelect(this.element, options);

    }

    // Fix the issue of the tom-select instance not being initialized when hitting back button of the browser
    disconnect() {
        if (this.tomSelectInstance) {
            this.tomSelectInstance.destroy();
        }
    }

}
