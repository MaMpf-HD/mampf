import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    confirmMessage: String
  }

  connect() {
    this.element.addEventListener("submit", this.confirm.bind(this))
  }

  confirm(event) {
    const select = this.element.querySelector("select[name='rosterable_id']")
    const selectedOption = select.options[select.selectedIndex]
    const isOverbooked = selectedOption.dataset.overbooked === "true"

    if (isOverbooked) {
      if (!window.confirm(this.confirmMessageValue)) {
        event.preventDefault()
      }
    }
  }
}
