import { Controller } from "@hotwired/stimulus";
import {
  normalizeDisplayMathLineBreaks,
  renderMathIn,
} from "~/js/katex_helper";

export default class extends Controller {
  static targets = ["editor", "preview", "warning", "failure"];

  static values = {
    cancelUrl: String,
    tooLarge: String,
    failed: String,
    unsaved: Boolean,
  };

  connect() {
    this.updatePreview();
    if (this.unsavedValue) this.showWarning();
    this.frame = this.element.closest("turbo-frame");
    this.boundKeepForm = this.keepForm.bind(this);
    this.frame?.addEventListener("turbo:frame-missing", this.boundKeepForm);
  }

  disconnect() {
    this.frame?.removeEventListener("turbo:frame-missing", this.boundKeepForm);
  }

  // Keeps the home form, and what is typed in it, when an HTML answer to its
  // submission lacks lecture-area: nginx refusing the upload, mostly.
  keepForm(event) {
    const { response } = event.detail;
    if (new URL(response.url).pathname !== new URL(this.element.action).pathname) return;

    event.preventDefault();
    this.showFailure(response.status);
  }

  // Covers the answers keepForm never sees: nginx's refusals are plain text,
  // and a dropped connection brings no answer at all. A turbo stream is the
  // app's own answer and shows its errors itself.
  reportFailedSubmission(event) {
    const { success, fetchResponse } = event.detail;
    if (success || fetchResponse?.contentType?.startsWith("text/vnd.turbo-stream.html")) return;

    this.showFailure(fetchResponse?.statusCode);
  }

  showFailure(status) {
    this.failureTarget.textContent = status === 413
      ? this.tooLargeValue
      : [this.failedValue, status && `(${status})`].filter(Boolean).join(" ");
    this.failureTarget.hidden = false;
  }

  updatePreview() {
    if (!this.hasEditorTarget || !this.hasPreviewTarget) return;

    this.previewTarget.innerHTML = normalizeDisplayMathLineBreaks(
      this.editorTarget.innerHTML,
    );
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
