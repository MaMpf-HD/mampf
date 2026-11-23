import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["row", "bulkSave", "dirtyCount", "form", "payload", "outdated"];

  connect() {
    this.newValues = [];
  }

  // A row that was swapped out - saved, or its hand-in taken back - has
  // nothing left to save; what was typed into it must not come back with
  // the next bulk save.
  rowTargetDisconnected(row) {
    this.newValues = this.newValues.filter(value => value.id !== row.dataset.rowId);
    this.updateBulkState();
  }

  // A row re-rendered by the server carries the current passing threshold;
  // if it differs from the heading's, the hint to reload is shown.
  rowTargetConnected(row) {
    if (!this.hasOutdatedTarget) return;

    const heading = this.element.querySelector("thead th.passed-col");
    const cell = row.querySelector("td.passed-col");
    if ((heading?.dataset.passingPoints ?? "") !== (cell?.dataset.passingPoints ?? "")) {
      this.outdatedTarget.hidden = false;
    }
  }

  reload() {
    window.location.reload();
  }

  rowDirty(event) {
    this.newValues = this.newValues.filter(
      value => !(value.id === event.detail.id && value.target === event.detail.target));
    this.newValues.push(event.detail);
    this.updateBulkState();
  }

  rowClean(event) {
    this.newValues = this.newValues.filter(
      value => !(value.id === event.detail.id && value.target === event.detail.target));
    this.updateBulkState();
  }

  updateBulkState() {
    const count = this.newValues.length;

    if (this.hasBulkSaveTarget) {
      this.bulkSaveTarget.disabled = count === 0;
    }
    if (this.hasDirtyCountTarget) {
      this.dirtyCountTarget.textContent = count;
      this.dirtyCountTarget.hidden = count === 0;
    }
  }

  submitAll() {
    this.payloadTarget.value = JSON.stringify(this.newValues);
    this.formTarget.requestSubmit();
  }
}
