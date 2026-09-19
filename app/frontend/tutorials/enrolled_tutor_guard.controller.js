import { Controller } from "@hotwired/stimulus";

// A lecturer may make a student the tutor of the group they are in - they
// would be marking their own sheets - but not without being told.
export default class extends Controller {
  static targets = ["select"];
  static values = { confirmOne: String, confirmOther: String };

  submit(event) {
    const enrolled = [...this.selectTarget.selectedOptions]
      .filter(option => option.dataset.enrolled === "true")
      .map(option => option.textContent.trim());
    if (enrolled.length === 0) return;

    const message = enrolled.length === 1 ? this.confirmOneValue : this.confirmOtherValue;
    if (!confirm(message.replace("%{names}", enrolled.join(", ")))) {
      event.preventDefault();
    }
  }
}
