import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["testType", "categoriesSection", "practicalTasksSection", "passingScoreSection", "passingScore"]
  static values = { 
    theoretical: String,
    practical: String
  }

  connect() {
    this.toggleSections()
  }

  toggleSections() {
    const selectedType = this.testTypeTarget.value
    
    if (selectedType === this.theoreticalValue) {
      this.showCategoriesSection()
      this.hidePracticalTasksSection()
      this.showPassingScoreSection()
    } else if (selectedType === this.practicalValue) {
      this.hideCategoriesSection()
      this.showPracticalTasksSection()
      this.hidePassingScoreSection()
      this.setPassingScoreTo100()
    } else {
      this.hideCategoriesSection()
      this.hidePracticalTasksSection()
      this.showPassingScoreSection()
    }
  }

  showCategoriesSection() {
    if (this.hasCategoriesSectionTarget) {
      this.categoriesSectionTarget.classList.remove('hidden')
    }
  }

  hideCategoriesSection() {
    if (this.hasCategoriesSectionTarget) {
      this.categoriesSectionTarget.classList.add('hidden')
    }
  }

  showPracticalTasksSection() {
    if (this.hasPracticalTasksSectionTarget) {
      this.practicalTasksSectionTarget.classList.remove('hidden')
    }
  }

  hidePracticalTasksSection() {
    if (this.hasPracticalTasksSectionTarget) {
      this.practicalTasksSectionTarget.classList.add('hidden')
    }
  }

  showPassingScoreSection() {
    if (this.hasPassingScoreSectionTarget) {
      this.passingScoreSectionTarget.classList.remove('hidden')
    }
  }

  hidePassingScoreSection() {
    if (this.hasPassingScoreSectionTarget) {
      this.passingScoreSectionTarget.classList.add('hidden')
    }
  }

  setPassingScoreTo100() {
    if (this.hasPassingScoreTarget) {
      this.passingScoreTarget.value = 100
    }
  }
}
