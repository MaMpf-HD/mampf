import { Controller } from "@hotwired/stimulus";
import { renderMathIn } from "~/js/katex_helper";

export default class extends Controller {
  static targets = ["editor", "preview", "warning"];

  static values = {
    cancelUrl: String,
  };

  connect() {
    this.updatePreview();
  }

  updatePreview() {
    if (!this.hasEditorTarget || !this.hasPreviewTarget) return;

    this.previewTarget.innerHTML = this.editorTarget.innerHTML;
    renderMathIn(this.previewTarget);
  }

  showWarning() {
    if (!this.hasWarningTarget) return;

    this.warningTarget.style.display = "block";
  }

  rejectAttachment(event) {
    event.preventDefault();
  }

  cancel(event) {
    event.preventDefault();
    if (!this.hasCancelUrlValue) return;

    const frame = this.element.closest("turbo-frame");
    if (!frame) return;

    const cancelUrl = new URL(this.cancelUrlValue, window.location.href)
      .toString();
    const frameUrl = frame.getAttribute("src")
      ? new URL(frame.getAttribute("src"), window.location.href).toString()
      : null;

    if (frameUrl === cancelUrl && typeof frame.reload === "function") {
      frame.reload();
      return;
    }

    frame.src = this.cancelUrlValue;
  }
}
