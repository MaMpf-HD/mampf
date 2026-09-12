import { Controller } from "@hotwired/stimulus";

// Narrows the rows to a name, a state and a group. Rows come back one at a
// time after a save, so every new row is measured against the filters too.
export default class extends Controller {
  static targets = ["row", "name", "status", "tutorial", "reset", "count", "empty"];

  rowTargetConnected(row) {
    if (!this.hasNameTarget) {
      return;
    }
    this.show(row);
    this.report();
  }

  rowTargetDisconnected() {
    if (!this.hasNameTarget) {
      return;
    }
    this.report();
  }

  apply() {
    this.rowTargets.forEach(row => this.show(row));
    this.report();
  }

  search() {
    this.apply();
  }

  reset() {
    this.nameTarget.value = "";
    this.statusTarget.value = "all";
    if (this.hasTutorialTarget) {
      this.tutorialTarget.value = "all";
    }
    this.apply();
  }

  show(row) {
    row.hidden = !this.matches(row);
  }

  matches(row) {
    const query = this.nameTarget.value.trim().toLowerCase();
    const status = this.statusTarget.value;
    const tutorial = this.hasTutorialTarget ? this.tutorialTarget.value : "all";
    return (query === "" || row.dataset.statusFilterName.toLowerCase().includes(query))
      && (status === "all" || row.dataset.statusFilterStatus === status)
      && (tutorial === "all" || (row.dataset.statusFilterTutorial || "none") === tutorial);
  }

  report() {
    const total = this.rowTargets.length;
    const shown = this.rowTargets.filter(row => !row.hidden).length;
    this.resetTarget.hidden = !this.filtering();
    this.countTarget.hidden = !this.filtering();
    this.countTarget.textContent = this.countTarget.dataset.template
      .replace("%{shown}", shown)
      .replace("%{total}", total);
    if (this.hasEmptyTarget) {
      this.emptyTarget.hidden = shown > 0;
    }
  }

  filtering() {
    return this.nameTarget.value.trim() !== ""
      || this.statusTarget.value !== "all"
      || (this.hasTutorialTarget && this.tutorialTarget.value !== "all");
  }
}
