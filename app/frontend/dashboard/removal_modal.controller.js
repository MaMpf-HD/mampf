import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";
import { sendDashboardRequest } from "./dashboard_request";

/**
 * Base for a dashboard card's removal-confirmation modal.
 */
export default class extends Controller {
  static targets = ["dialog"];
  static values = { url: String, lectureId: Number };

  dialogTargetConnected(dialog) {
    this.dialog = dialog;

    // placeholder node to mark original position of dialog in DOM
    this.dialogPlaceholder = document.createComment("");
    this.dialog.before(this.dialogPlaceholder);
    document.body.appendChild(this.dialog);

    this.restoreDialogPosition = () => this.dialogPlaceholder.replaceWith(this.dialog);
    document.addEventListener("turbo:before-cache", this.restoreDialogPosition);

    this.boundBindings = this.bindings().map(([selector, handler]) => {
      const button = this.dialog.querySelector(selector);
      button?.addEventListener("click", handler);
      return [button, handler];
    });
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.restoreDialogPosition);
    this.boundBindings?.forEach(([button, handler]) => {
      button?.removeEventListener("click", handler);
    });
    this.releaseDialog();

    this.dialog = null;
  }

  /**
   * Takes the dialog out of <body> again. A Turbo Stream that replaces the
   * card disconnects this controller without a turbo:before-cache, so the
   * dialog would otherwise outlive its card.
   */
  releaseDialog() {
    if (this.dialog?.parentElement !== document.body) return;

    Modal.getInstance(this.dialog)?.dispose();
    if (this.dialogPlaceholder?.isConnected) {
      this.dialogPlaceholder.replaceWith(this.dialog);
    }
    else {
      this.dialog.remove();
    }
  }

  open() {
    if (!this.dialog) return;

    Modal.getOrCreateInstance(this.dialog).show();
  }

  // Subclasses return [[selector, handler], ...] for their confirm button(s),
  // e.g. [["[data-foo-confirm]", () => this.confirm()]].
  bindings() {
    return [];
  }

  async confirmRemoval(url, detail) {
    const response = await sendDashboardRequest(url, "DELETE");

    if (!response.ok) {
      console.error(`${this.identifier}: failed (${response.status})`);
      Modal.getInstance(this.dialog)?.hide();
      return;
    }

    const html = await response.text();
    // Let the modal finish closing (backdrop, body class) before the stream
    // replaces this card and disconnects the controller.
    this.applyOnceHidden(() => {
      window.Turbo.renderStreamMessage(html);
      window.dispatchEvent(new CustomEvent("bookmark:changed", { detail }));
    });
  }

  applyOnceHidden(callback) {
    const modal = Modal.getInstance(this.dialog);
    if (!modal) {
      callback();
      return;
    }

    this.dialog.addEventListener("hidden.bs.modal", callback, { once: true });
    modal.hide();
  }
}
