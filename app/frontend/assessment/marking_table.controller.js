import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["row", "bulkSave", "dirtyCount", "form", "payload"];

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
