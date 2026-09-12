import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";

/**
 * Base for a dashboard card's removal-confirmation modal. The dialog is moved
 * to <body> on connect (else the card's CSS transform tilts the modal along
 * with it), which also moves it out of this controller's DOM subtree, so
 * confirm buttons are wired up by hand instead of via data-action. Not
 * registered directly - subclasses implement `bindings()`.
 */
export default class extends Controller {
  static targets = ["dialog"];
  static values = { url: String, lectureId: Number };

  connect() {
    if (!this.hasDialogTarget) return;

    this.dialog = this.dialogTarget;
    document.body.appendChild(this.dialog);

    this.boundBindings = this.bindings().map(([selector, handler]) => {
      const button = this.dialog.querySelector(selector);
      button?.addEventListener("click", handler);
      return [button, handler];
    });
  }

  disconnect() {
    if (!this.dialog) return;

    this.boundBindings?.forEach(([button, handler]) => {
      button?.removeEventListener("click", handler);
    });
    Modal.getInstance(this.dialog)?.dispose();
    this.dialog.remove();
  }

  open() {
    Modal.getOrCreateInstance(this.dialog).show();
  }

  // Subclasses return [[selector, handler], ...] for their confirm button(s),
  // e.g. [["[data-foo-confirm]", () => this.confirm()]].
  bindings() {
    return [];
  }

  async confirmRemoval(url, detail) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;

    const response = await fetch(url, {
      method: "DELETE",
      headers: {
        "Accept": "text/vnd.turbo-stream.html",
        "X-CSRF-Token": csrfToken,
      },
    });

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
