import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["bulkSave", "form", "payload"];

  connect() {
    this.newValues = [];
  }

  rowDirty(event) {
    this.newValues = this.newValues.filter(value => value.id !== event.detail.id);
    this.newValues.push(event.detail);
    this.updateBulkState();
  }

  rowClean(event) {
    this.newValues = this.newValues.filter(value => value.id !== event.detail.id);
    this.updateBulkState();
  }

  updateBulkState() {
    const anyDirty = this.newValues.length > 0;

    if (this.hasBulkSaveTarget) {
      this.bulkSaveTarget.disabled = !anyDirty;
    }
  }

  submitAll() {
    this.payloadTarget.value = JSON.stringify(this.newValues);
    this.formTarget.requestSubmit();
  }
}
