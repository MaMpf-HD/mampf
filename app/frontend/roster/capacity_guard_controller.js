import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input"];
  static values = {
    currentCount: Number,
    confirmMessage: String,
  };

  submit(event) {
    const newCapacity = parseInt(this.inputTarget.value, 10);

    // If capacity is empty or not a number, we assume it's infinite/valid for now
    // or let server-side validation handle it.
    if (isNaN(newCapacity)) return;

    if (newCapacity < this.currentCountValue) {
      if (!confirm(this.confirmMessageValue)) {
        event.preventDefault();
      }
    }
  }
}
