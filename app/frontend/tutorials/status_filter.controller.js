import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  filter(event) {
    const selected = event.currentTarget.dataset.statusFilterValue;

    this.element.querySelectorAll("button[data-status-filter-value]").forEach((btn) => {
      const active = btn.dataset.statusFilterValue === selected;
      btn.classList.toggle("btn-dark", active);
      btn.classList.toggle("btn-outline-secondary", !active);
    });

    this.element.querySelectorAll("tr[data-status]").forEach((row) => {
      const match = selected === "all" || row.dataset.status === selected;
      row.style.display = match ? "" : "none";
    });
  }
}
