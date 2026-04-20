import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["timeText"]
  static values = {
    remaining: Number,
    resultsUrl: String,
    warningThreshold: { type: Number, default: 300 }
  }

  connect() {
    this.tick = this.tick.bind(this)
    this.updateDisplay()
    this.intervalId = setInterval(this.tick, 1000)
  }

  disconnect() {
    if (this.intervalId) clearInterval(this.intervalId)
  }

  tick() {
    let remaining = (this.remainingValue || 0) - 1
    if (remaining <= 0) {
      this.remainingValue = 0
      this.navigateToResults()
      return
    }
    this.remainingValue = remaining
    this.updateDisplay()
  }

  updateDisplay() {
    const minutes = Math.floor(this.remainingValue / 60)
    const seconds = this.remainingValue % 60
    if (this.hasTimeTextTarget) {
      const template = this.element.dataset.timeTemplate || "%{minutes} min %{seconds} s left"
      this.timeTextTarget.textContent = template
        .replace("%{minutes}", minutes)
        .replace("%{seconds}", seconds)
    }

    if (this.remainingValue <= this.warningThresholdValue && this.remainingValue > 0) {
      this.element.classList.add('warning')
    }
  }

  navigateToResults() {
    if (this.resultsUrlValue) {
      window.location.href = this.resultsUrlValue
    }
  }
}
