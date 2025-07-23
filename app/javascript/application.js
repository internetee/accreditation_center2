// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "cookieconsent-config"
import '@popperjs/core'
import Header from "src/header"
import Select from "src/select"
import Tooltip from "src/tooltip"

class App {
  constructor() {
      this.bindUiEvents()
  }
  
  bindUiEvents() {
      var locale = document.querySelector('body').dataset.locale

      document.querySelectorAll('.tooltip').forEach(elem => {
        new Tooltip(elem, 'click')
      })

      document.querySelectorAll('.simple_tooltip').forEach(elem => {
        new Tooltip(elem, 'mouseenter focus')
      })

      new Header(document.querySelector('.layout--header-bottom'))

      document.querySelectorAll('select:not(.flatpickr-monthDropdown-months)').forEach(elem => {
        new Select(elem, { itemSelectText: '' })
      })

      const per_page_select = document.getElementById('per_page')
        if (per_page_select) {
          per_page_select.onchange = function(evt){
            var value = evt.target.value
            // if(value){window.location='?per_page='+value;}

            const urlParams = new URLSearchParams(window.location.search)
            urlParams.set('per_page', value)
            window.location.search = urlParams
          }
        }
    }
}

new App()
