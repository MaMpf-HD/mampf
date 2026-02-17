import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input"];
  static values = {
    currentCount: Number,
    confirmMessage: String,
    originalCapacity: Number,
  };

  submit(event) {
    const newCapacity = parseInt(this.inputTarget.value, 10);

    // If capacity is empty or not a number, we assume it's infinite/valid for now
    // or let server-side validation handle it.
    if (isNaN(newCapacity)) return;

    // Only show warning if capacity actually changed and is now below member count
    const capacityChanged = newCapacity !== this.originalCapacityValue;
    const isBelowMemberCount = newCapacity < this.currentCountValue;

    if (capacityChanged && isBelowMemberCount) {
      if (!confirm(this.confirmMessageValue)) {
        event.preventDefault();
      }
    }
  }
}
