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
    if (key === "tutorial") {
      this.selectedTutorial = "all";
      this.selectedTutorialLabel = null;
    }
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

    this.activeFiltersTarget.innerHTML = "";

    if (chips.length === 0) {
      return;
    }

    chips.forEach(chip => this.activeFiltersTarget.append(chip));

    const clearAllBtn = document.createElement("button");
    clearAllBtn.className = "btn btn-sm btn-outline-secondary";
    clearAllBtn.dataset.action = "click->status-filter#clearAllFilters";
    clearAllBtn.textContent = "Clear all";
    this.activeFiltersTarget.append(clearAllBtn);
  }

  chipHtml(key, label) {
    const span = document.createElement("span");
    span.className = "badge bg-light text-dark border d-inline-flex align-items-center gap-1";
    span.append(document.createTextNode(label + " "));

    const icon = document.createElement("i");
    icon.className = "bi bi-x clickable";
    icon.dataset.action = "click->status-filter#clearFilter";
    icon.dataset.filterKey = key;
    span.append(icon);

    return span;
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
