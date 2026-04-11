import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input"];
  static values = {
    currentCount: Number,
    confirmMessage: String,
    originalCapacity: String,
  };

  submit(event) {
    const newCapacity = parseInt(this.inputTarget.value, 10);

    if (isNaN(newCapacity)) return;

    const originalCapacity = parseInt(this.originalCapacityValue, 10);
    const wasUnlimited = isNaN(originalCapacity);
    const capacityChanged = wasUnlimited || newCapacity !== originalCapacity;
    const isBelowMemberCount = newCapacity < this.currentCountValue;

    if (capacityChanged && isBelowMemberCount) {
      if (!confirm(this.confirmMessageValue)) {
        event.preventDefault();
      }
    }
  }
}
