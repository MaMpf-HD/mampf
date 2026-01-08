import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["row", "allButton", "unassignedButton", "allCount", "unassignedCount"];

  connect() {
    this.updateCounts();
  }

  showAll() {
    this.rowTargets.forEach(row => row.classList.remove("d-none"));
    this.allButtonTarget.classList.add("active");
    this.unassignedButtonTarget.classList.remove("active");
  }

  showUnassigned() {
    this.rowTargets.forEach((row) => {
      const isUnassigned = row.dataset.status === "unassigned";
      row.classList.toggle("d-none", !isUnassigned);
    });
    this.allButtonTarget.classList.remove("active");
    this.unassignedButtonTarget.classList.add("active");
  }

  updateCounts() {
    const unassignedCount = this.rowTargets.filter(
      row => row.dataset.status === "unassigned",
    ).length;

    if (this.hasAllCountTarget) {
      this.allCountTarget.textContent = this.rowTargets.length;
    }
    if (this.hasUnassignedCountTarget) {
      this.unassignedCountTarget.textContent = unassignedCount;
    }
  }
}
