# Pin npm packages by running ./bin/importmap
pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "dsfr", to: "dsfr.module.min.js"
pin "tom-select", to: "tom-select.js"
pin "set_time_zone", to: "controllers/set_time_zone.js"
