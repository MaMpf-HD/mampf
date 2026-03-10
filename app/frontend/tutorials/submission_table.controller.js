import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["bulkSave"];

  connect() {
    this.dirtyRows = new Set();
  }

  rowDirty(event) {
    this.dirtyRows.add(event.detail.id);
    this.updateBulkState();
  }

  rowClean(event) {
    this.dirtyRows.delete(event.detail.id);
    this.updateBulkState();
  }

  updateBulkState() {
    const anyDirty = this.dirtyRows.size > 0;

    if (this.hasBulkSaveTarget) {
      this.bulkSaveTarget.disabled = !anyDirty;
    }
  }
}
