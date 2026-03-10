import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "save"];

  connect() {
    this.originalValues = this.inputTargets.map(i => i.value);
  }

  markDirty() {
    const dirty = this.inputTargets.some((input, idx) => input.value != this.originalValues[idx]);

    if (dirty) {
      this.element.classList.add("dirty");
      this.element.classList.add("row-dirty");
      this.dispatch("dirty", { detail: { id: this.element.dataset.submissionRowId } });
      if (this.hasSaveTarget) this.saveTarget.disabled = false;
    }
    else {
      this.element.classList.remove("dirty");
      this.element.classList.remove("row-dirty");
      this.dispatch("clean", { detail: { id: this.element.dataset.submissionRowId } });
      if (this.hasSaveTarget) this.saveTarget.disabled = true;
    }
  }
}
