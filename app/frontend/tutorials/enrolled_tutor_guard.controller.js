import { Controller } from "@hotwired/stimulus";

// A lecturer may make a student the tutor of the group they are in, but not
// without being told that they would be marking their own sheets.
export default class extends Controller {
  static targets = ["select"];
  static values = { confirmOne: String, confirmOther: String };

  // Whoever was tutor already when the form opened has been accepted once;
  // asking again on every later edit would wear the warning out.
  connect() {
    this.accepted = new Set(this.enrolledSelected().map(option => option.value));
  }

  submit(event) {
    if (event.defaultPrevented) return;

    const names = this.enrolledSelected()
      .filter(option => !this.accepted.has(option.value))
      .map(option => option.textContent.trim());
    if (names.length === 0) return;

    const message = names.length === 1 ? this.confirmOneValue : this.confirmOtherValue;
    if (!confirm(message.replace("%{names}", names.join(", ")))) {
      event.preventDefault();
    }
  }

  enrolledSelected() {
    return [...this.selectTarget.selectedOptions]
      .filter(option => option.dataset.enrolled === "true");
  }
}
