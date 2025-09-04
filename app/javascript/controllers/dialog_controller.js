import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["flash", "closeButton"]

  connect() {
    // Initialize the dialog when the controller connects
    this.setupEventListeners()
    
    // Listen for Turbo Frame events
    this.element.addEventListener('turbo:frame-load', this.frameLoaded.bind(this))
  }

  disconnect() {
    // Clean up event listeners when the controller disconnects
    this.removeEventListeners()
    
    // Remove Turbo Frame event listener
    this.element.removeEventListener('turbo:frame-load', this.frameLoaded.bind(this))
  }

  setupEventListeners() {
    // Setup close button listener
    if (this.hasCloseButtonTarget) {
      this.closeButtonTarget.addEventListener('click', this.close.bind(this))
    }
  }

  removeEventListeners() {
    if (this.hasCloseButtonTarget) {
      this.closeButtonTarget.removeEventListener('click', this.close.bind(this))
    }
  }

  open() {
    // Add open class to dialog
    this.element.classList.add('open')

    // Clear flash message if it exists
    this.clearFlash()
  }

  close(event) {
    if (event) {
      event.preventDefault()
    }
    
    // Remove open class from dialog
    this.element.classList.remove('open')
  }

  clearFlash() {
    if (this.hasFlashTarget) {
      this.flashTarget.innerHTML = ""
    }
  }

  // Method to handle Turbo Frame loading
  frameLoaded() {
    this.open()
  }
} 