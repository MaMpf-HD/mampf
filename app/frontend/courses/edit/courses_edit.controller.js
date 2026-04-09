import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "warning",
    "newLectureButton",
    "newMediumButton",
    "newTagButton",
    "form",
    "trixEditor",
    "imagePreview",
    "imageMeta",
    "uploadImageHidden",
    "detachImageInput",
  ];

  connect() {
    this.initializeTrixEditor();
  }

  disconnect() {
    if (this.hasTrixEditorTarget && this.trixChangeHandler) {
      this.trixEditorTarget.removeEventListener("trix-change", this.trixChangeHandler);
    }
  }

  onFormChange() {
    this.showWarning();
  }

  detachImage() {
    if (this.hasUploadImageHiddenTarget) this.uploadImageHiddenTarget.value = "";
    if (this.hasImageMetaTarget) this.imageMetaTarget.style.display = "none";
    if (this.hasImagePreviewTarget) this.imagePreviewTarget.style.display = "none";
    if (this.hasDetachImageInputTarget) this.detachImageInputTarget.value = "true";
    this.showWarning();

    const userWarning = document.getElementById("user-basics-warning");
    if (userWarning) userWarning.style.display = "block";
  }

  showWarning() {
    if (this.hasWarningTarget) this.warningTarget.style.display = "block";
    if (this.hasNewLectureButtonTarget) this.newLectureButtonTarget.style.display = "none";
    if (this.hasNewMediumButtonTarget) this.newMediumButtonTarget.style.display = "none";
    if (this.hasNewTagButtonTarget) this.newTagButtonTarget.style.display = "none";
  }

  initializeTrixEditor() {
    if (!this.hasTrixEditorTarget) return;

    const content = this.trixEditorTarget.dataset.content;
    const editor = this.trixEditorTarget.editor;
    if (!editor || content == null) return;

    editor.setSelectedRange([0, 65535]);
    editor.deleteInDirection("forward");
    editor.insertHTML(content);

    if (document.activeElement instanceof HTMLElement) document.activeElement.blur();

    this.trixChangeHandler = () => this.showWarning();
    this.trixEditorTarget.addEventListener("trix-change", this.trixChangeHandler);
  }
}
