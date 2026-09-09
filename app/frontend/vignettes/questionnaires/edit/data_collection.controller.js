import { Controller } from "@hotwired/stimulus";

/**
 * Shows the consent text only while data collection is switched on, and keeps
 * the two from being saved apart: without a text there is nothing for a student
 * to consent to. The database refuses that combination too; this is the part
 * the teacher gets to see.
 */
export default class extends Controller {
  static targets = ["toggle", "text", "editor", "error"];

  connect() {
    this.refresh();
  }

  refresh() {
    this.textTarget.hidden = !this.toggleTarget.checked;
    this.errorTarget.hidden = true;
  }

  guard(event) {
    if (!this.toggleTarget.checked || this.editorTarget.innerText.trim() !== "") {
      return;
    }

    event.preventDefault();
    this.errorTarget.hidden = false;
    this.editorTarget.focus();
  }
}
