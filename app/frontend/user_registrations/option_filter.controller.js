import { Controller } from "@hotwired/stimulus";

/**
 * Keeps an option the student already holds or ranked visible while the list
 * is shortened or searched; `data-keep` marks it as rendered by the server.
 */
export default class extends Controller {
  static targets = ["row", "query", "more", "empty"];
  static values = { limit: Number };

  connect() {
    this.expanded = false;
    this.filter();
  }

  showAll() {
    this.expanded = true;
    this.filter();
  }

  filter() {
    const query = this.hasQueryTarget ? this.queryTarget.value.trim().toLowerCase() : "";
    let shown = 0;

    this.rowTargets.forEach((row, index) => {
      const matches = row.dataset.keep === "true" || (query
        ? row.dataset.filterText.includes(query)
        : this.expanded || index < this.limitValue);
      row.hidden = !matches;
      if (matches) shown += 1;
    });

    if (this.hasMoreTarget) this.moreTarget.hidden = Boolean(query) || this.expanded;
    if (this.hasEmptyTarget) this.emptyTarget.hidden = shown > 0;
  }
}
