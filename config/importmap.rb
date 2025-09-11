# Pin npm packages by running ./bin/importmap
pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "dsfr", to: "dsfr.module.min.js"
pin "tom-select", to: "tom-select.js"
pin "ahoy" # @1.0.1
pin "track_tabs", to: "track_tabs.js"
pin "os" # @2.1.0
pin "dsfr-chart", to: "dsfr-chart.js"
