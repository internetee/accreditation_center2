import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["role", "field"]

  connect() {
    this.toggle()
  }

  toggle() {
    if (!this.hasRoleTarget) return

    const selectedRole = this.roleTarget.value

    this.fieldTargets.forEach((field) => {
      const visibleFor = (field.dataset.roleFormVisibleForValue || "")
        .split(",")
        .map((value) => value.trim())
        .filter(Boolean)
      const requiredFor = (field.dataset.roleFormRequiredForValue || "")
        .split(",")
        .map((value) => value.trim())
        .filter(Boolean)

      const isVisible = visibleFor.length === 0 || visibleFor.includes(selectedRole)
      field.classList.toggle("hidden", !isVisible)

      field.querySelectorAll("input, select, textarea").forEach((input) => {
        if (requiredFor.length > 0) {
          input.required = isVisible && requiredFor.includes(selectedRole)
        }

        if (!isVisible && input.type === "password") {
          input.value = ""
        }
      })
    })
  }
}
