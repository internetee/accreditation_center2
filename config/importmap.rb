# Pin npm packages by running ./bin/importmap

pin 'application'
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/src", under: "src", to: "src"
pin "choices.js" # @10.2.0
pin "process" # @2.1.0
pin "flatpickr" # @4.6.13
pin "tippy.js" # @6.3.7
# pin "@popperjs/core", to: "@popperjs--core.js" # @2.11.8
pin "@popperjs/core", to: "@popperjs--core--esm.js" # @2.11.8
pin "vanilla-cookieconsent" # @3.1.0
pin "cookieconsent-config", to: "cookieconsent-config.js"
