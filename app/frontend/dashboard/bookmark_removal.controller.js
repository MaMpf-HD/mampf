import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";

/**
 * The small "x" on a bookmarked dashboard card. It opens a confirmation modal
 * and, once confirmed, removes the lecture from the student's bookmarks and
 * reloads so the board reflects the change.
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
  static values = { url: String };

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
        "Accept": "application/json",
        "X-CSRF-Token": csrfToken,
      },
    });

    if (response.ok) {
      window.location.reload();
      return;
    }

    console.error(`bookmark-removal: failed (${response.status})`);
    Modal.getInstance(this.dialog)?.hide();
  }
}
