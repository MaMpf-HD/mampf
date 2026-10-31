import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "submit"];
  static values = { word: String };

  connect() {
    this.check();
  }

  check() {
    this.submitTarget.disabled = this.inputTarget.value.trim() !== this.wordValue;
  }
}
