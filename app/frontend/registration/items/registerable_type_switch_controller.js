import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "cohortSettings"]

  connect() {
    this.toggle()
  }

  toggle() {
    const type = this.selectTarget.value
    if (type === "Cohort") {
      this.cohortSettingsTarget.classList.remove("hidden")
      this.cohortSettingsTarget.classList.remove("d-none")
    } else {
      this.cohortSettingsTarget.classList.add("d-none")
    }
  }
}
