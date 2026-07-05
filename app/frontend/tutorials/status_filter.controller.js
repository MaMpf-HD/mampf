import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["activeFilters"];

  connect() {
    this.selectedStatus = "all";
    this.selectedTutorial = "all";
    this.selectedTutorialLabel = null;
    this.searchQuery = "";
  }

  filterStatus(event) {
    this.selectedStatus = event.currentTarget.dataset.statusFilterStatusValue;
    this.applySearchFilter();
    this.renderActiveFilters();
  }

  filterTutorial(event) {
    this.selectedTutorial = event.currentTarget.dataset.statusFilterTutorialValue;
    this.selectedTutorialLabel = event.currentTarget.textContent.trim();
    this.applySearchFilter();
    this.renderActiveFilters();
  }

  clearFilter(event) {
    const key = event.currentTarget.dataset.filterKey;
    if (key === "status") this.selectedStatus = "all";
    if (key === "tutorial") { this.selectedTutorial = "all"; this.selectedTutorialLabel = null; }
    this.applySearchFilter();
    this.renderActiveFilters();
  }

  clearAllFilters() {
    this.selectedStatus = "all";
    this.selectedTutorial = "all";
    this.selectedTutorialLabel = null;
    this.applySearchFilter();
    this.renderActiveFilters();
  }

  renderActiveFilters() {
    const chips = [];

    if (this.selectedStatus !== "all") {
      chips.push(this.chipHtml("status", this.selectedStatus));
    }
    if (this.selectedTutorial !== "all") {
      chips.push(this.chipHtml("tutorial", this.selectedTutorialLabel || this.selectedTutorial));
    }

    if (chips.length === 0) {
      this.activeFiltersTarget.innerHTML = "";
      return;
    }

    this.activeFiltersTarget.innerHTML = chips.join("") + `
      <button
        class="btn btn-sm btn-outline-secondary"
        data-action="click->status-filter#clearAllFilters"
      >
        Clear all
      </button>
    `;
  }

  chipHtml(key, label) {
    return `
      <span class="badge bg-light text-dark border d-inline-flex align-items-center gap-1">
        ${label}
        <i
          class="bi bi-x clickable"
          data-action="click->status-filter#clearFilter"
          data-filter-key="${key}"
        ></i>
      </span>
    `;
  }

  applySearchFilter() {
    this.element.querySelectorAll("tr[data-status-filter-status]").forEach((row) => {
      const matchStatus = (this.selectedStatus === "all"
        || row.dataset.statusFilterStatus === this.selectedStatus);
      const matchName = row.dataset.statusFilterName.toLowerCase().includes(this.searchQuery);
      const matchTutorial = (this.selectedTutorial === "all"
        || row.dataset.statusFilterTutorial === this.selectedTutorial);
      row.style.display = matchStatus && matchName && matchTutorial ? "" : "none";
    });
  }

  search(event) {
    this.searchQuery = event.currentTarget.value.toLowerCase();
    this.applySearchFilter();
  }
}
