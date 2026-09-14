import { Controller } from "@hotwired/stimulus";

// Narrows the rows to a name, a state and a group. Rows come back one at a
// time after a save, so every new row is measured against the filters too.
// A sheet from before there were states offers no state filter.
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
    if (this.hasStatusTarget) {
      this.statusTarget.value = "all";
    }
    if (this.hasTutorialTarget) {
      this.tutorialTarget.value = "all";
    }
    this.apply();
  }

  show(row) {
    row.hidden = !this.matches(row);
  }

  // The state select also offers spots a row can be in beyond its state,
  // as "flag:<name>" options; a row lists its flags space-separated.
  matches(row) {
    const query = this.nameTarget.value.trim().toLowerCase();
    const status = this.hasStatusTarget ? this.statusTarget.value : "all";
    const tutorial = this.hasTutorialTarget ? this.tutorialTarget.value : "all";
    return (query === "" || row.dataset.statusFilterName.toLowerCase().includes(query))
      && this.matchesStatus(row, status)
      && (tutorial === "all" || (row.dataset.statusFilterTutorial || "none") === tutorial);
  }

  matchesStatus(row, status) {
    if (status === "all") {
      return true;
    }
    if (status.startsWith("flag:")) {
      return (row.dataset.statusFilterFlags || "").split(" ").includes(status.slice(5));
    }
    return row.dataset.statusFilterStatus === status;
  }

  showStatus({ params: { status } }) {
    this.statusTarget.value = status;
    this.apply();
  }

  report() {
    const total = this.rowTargets.length;
    const shown = this.rowTargets.filter(row => !row.hidden).length;
    if (this.hasResetTarget) {
      this.resetTarget.hidden = !this.filtering();
    }
    if (this.hasCountTarget) {
      this.countTarget.hidden = !this.filtering();
      this.countTarget.textContent = this.countTarget.dataset.template
        .replace("%{shown}", shown)
        .replace("%{total}", total);
    }
    if (this.hasEmptyTarget) {
      this.emptyTarget.hidden = shown > 0;
    }
  }

  filtering() {
    return this.nameTarget.value.trim() !== ""
      || (this.hasStatusTarget && this.statusTarget.value !== "all")
      || (this.hasTutorialTarget && this.tutorialTarget.value !== "all");
  }
}
