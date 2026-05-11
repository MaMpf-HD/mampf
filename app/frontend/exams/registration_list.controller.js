import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["entry", "noResults"];

  filter(event) {
    const query = event.target.value.trim().toLowerCase();
    let anyVisible = false;

    this.entryTargets.forEach((entry) => {
      const searchText = entry.dataset.studentSearch || "";
      const matches = !query || searchText.includes(query);
      entry.classList.toggle("d-none", !matches);
      if (matches) anyVisible = true;
    });

    if (this.hasNoResultsTarget) {
      this.noResultsTarget.classList.toggle("d-none", anyVisible);
    }
  }
}
