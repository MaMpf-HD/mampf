import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "row"];

  filter() {
    const query = this.inputTarget.value.toLowerCase();
    this.rowTargets.forEach((row) => {
      const text = row.innerText.toLowerCase();
      row.style.display = text.includes(query) ? "" : "none";
    });
  }
}
