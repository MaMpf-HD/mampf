import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.selectedStatus = "all";
    this.searchQuery = "";
  }

  filter(event) {
    const selected = event.currentTarget.dataset.statusFilterValue;
    this.selectedStatus = selected;

    this.element.querySelectorAll("button[data-status-filter-value]").forEach((btn) => {
      const active = btn.dataset.statusFilterValue === selected;
      btn.classList.toggle("btn-dark", active);
      btn.classList.toggle("btn-outline-secondary", !active);
    });

    this.applySearchFilter();
  }

  applySearchFilter() {
    this.element.querySelectorAll("tr[data-status-filter-status]").forEach((row) => {
      const matchStatus = (this.selectedStatus === "all"
        || row.dataset.statusFilterStatus === this.selectedStatus);
      const matchName = row.dataset.statusFilterName.toLowerCase().includes(this.searchQuery);
      row.style.display = matchStatus && matchName ? "" : "none";
    });
  }

  search(event) {
    this.searchQuery = event.currentTarget.value.toLowerCase();
    this.applySearchFilter();
  }
}
