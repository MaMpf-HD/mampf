import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["gradeInput", "noteInput", "form", "refreshForm", "gradePayload", "notePayload", "save"];

  connect() {
    this.originalGrade = this.hasGradeInputTarget ? this.gradeInputTarget.value : null;
    this.originalNote = this.hasNoteInputTarget ? this.noteInputTarget.value : null;
    if (this.hasSaveTarget) {
      this.saveTarget.disabled = true;
    }
  }

  onFieldChanged() {
    this.markDirty();
  }

  saveRow() {
    if (this.hasGradeInputTarget && this.hasGradePayloadTarget) {
      this.gradePayloadTarget.value = this.gradeInputTarget.value;
    }
    if (this.hasNoteInputTarget && this.hasNotePayloadTarget) {
      this.notePayloadTarget.value = this.noteInputTarget.value;
    }
    this.formTarget.requestSubmit();
  }

  refreshRow() {
    this.refreshFormTarget.requestSubmit();
  }

  markDirty() {
    const gradeDirty = this.hasGradeInputTarget && this.gradeInputTarget.value !== this.originalGrade;
    const noteDirty = this.hasNoteInputTarget && this.noteInputTarget.value !== this.originalNote;

    if (gradeDirty || noteDirty) {
      this.handleDirty();
    }
    else {
      this.handleClean();
    }
  }

  handleDirty() {
    this.element.classList.add("row-dirty");
    this.dispatch("dirty", {
      prefix: false,
      bubbles: true,
      detail: { id: this.element.dataset.userRowId, target: "participation" },
    });
    if (this.hasSaveTarget) this.saveTarget.disabled = false;
  }

  handleClean() {
    this.element.classList.remove("row-dirty");
    this.dispatch("clean", {
      prefix: false,
      bubbles: true,
      detail: { id: this.element.dataset.userRowId, target: "participation" },
    });
    if (this.hasSaveTarget) this.saveTarget.disabled = true;
  }
}
