import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";

/**
 * The small "x" on a bookmarked dashboard card. It opens a confirmation modal
 * and, once confirmed, removes the lecture from the student's bookmarks.
 *
 * The request comes back as a Turbo Stream that re-renders the lecture bands,
 * so the card drops out of the "Bookmarked" section (and the section itself
 * goes once it is empty). A `bookmark:changed` event then flips the matching
 * bookmark button in the search results below.
 *
 * The dialog is moved to <body> on connect: the card is rotated with a CSS
 * transform, which would otherwise become the containing block for the
 * fixed-positioned modal and tilt it along with the card. That also takes the
 * dialog out of this controller's DOM subtree, so its confirm button is wired
 * up here by hand rather than with a data-action (the Bootstrap
 * data-bs-dismiss buttons keep working on their own).
 */
export default class extends Controller {
  static targets = ["dialog"];
  static values = { url: String, lectureId: Number };

  connect() {
    if (!this.hasDialogTarget) return;

    this.dialog = this.dialogTarget;
    document.body.appendChild(this.dialog);

    this.onConfirm = this.confirm.bind(this);
    const selector = "[data-bookmark-removal-confirm]";
    this.confirmButton = this.dialog.querySelector(selector);
    this.confirmButton?.addEventListener("click", this.onConfirm);
  }

  disconnect() {
    if (!this.dialog) return;

    this.confirmButton?.removeEventListener("click", this.onConfirm);
    Modal.getInstance(this.dialog)?.dispose();
    this.dialog.remove();
  }

  open() {
    Modal.getOrCreateInstance(this.dialog).show();
  }

  async confirm() {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;

    const response = await fetch(this.urlValue, {
      method: "DELETE",
      headers: {
        "Accept": "text/vnd.turbo-stream.html",
        "X-CSRF-Token": csrfToken,
      },
    });

    if (!response.ok) {
      console.error(`bookmark-removal: failed (${response.status})`);
      Modal.getInstance(this.dialog)?.hide();
      return;
    }

    const html = await response.text();
    // Let the modal finish closing (backdrop, body class) before the stream
    // replaces this card and disconnects the controller.
    this.applyOnceHidden(() => {
      window.Turbo.renderStreamMessage(html);
      window.dispatchEvent(new CustomEvent("bookmark:changed", {
        detail: { lectureId: this.lectureIdValue, bookmarked: false },
      }));
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
