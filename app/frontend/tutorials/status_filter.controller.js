import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.selectedStatus = "all";
    this.selectedTutorial = "all";
    this.searchQuery = "";
  }

  filterStatus(event) {
    const selected = event.currentTarget.dataset.statusFilterStatusValue;
    console.log(`Selected status: ${selected}`);
    this.selectedStatus = selected;
    this.applySearchFilter();
  }

  filterTutorial(event) {
    this.selectedTutorial = event.currentTarget.dataset.statusFilterTutorialValue;
    this.applySearchFilter();
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
