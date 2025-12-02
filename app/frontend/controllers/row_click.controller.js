import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  visit(event) {
    // Do not trigger if the user is selecting text
    if (window.getSelection().toString().length > 0) return

    // Do not trigger if the user clicked an interactive element directly
    if (event.target.closest("a, button, input, select")) return

    const link = this.element.querySelector("a[data-row-link]")
    if (link) link.click()
  }
}
