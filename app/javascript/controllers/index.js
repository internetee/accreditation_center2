// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
// When lazy loading, controllers are not loaded until their data-controller identifier is encountered in the DOM
// lazyLoadControllersFrom("controllers", application)
