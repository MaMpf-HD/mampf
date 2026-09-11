import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";

/**
 * The small "x" on a rejected-registration dashboard card. It opens a
 * confirmation modal offering two outcomes: keep the lecture as a plain
 * bookmark, or remove it from the dashboard entirely. Either way the
 * rejected registration is only dismissed (hidden), never deleted - see
 * Registration::UserRegistration#dismiss!.
 *
 * The request comes back as a Turbo Stream that re-renders the lecture
 * bands, same as bookmark-removal. The dialog is moved to <body> for the
 * same reason (the card's CSS transform would otherwise tilt it), so both
 * confirm buttons are wired up here by hand rather than with data-actions.
 */
export default class extends Controller {
  static targets = ["dialog"];
  static values = { url: String, lectureId: Number };

  connect() {
    if (!this.hasDialogTarget) return;

    this.dialog = this.dialogTarget;
    document.body.appendChild(this.dialog);

    this.onKeepBookmarked = () => this.confirm(true);
    this.onRemoveEntirely = () => this.confirm(false);

    this.keepButton = this.dialog.querySelector(
      "[data-registration-notice-removal-keep-bookmarked]"
    );
    this.removeButton = this.dialog.querySelector(
      "[data-registration-notice-removal-remove-entirely]"
    );
    this.keepButton?.addEventListener("click", this.onKeepBookmarked);
    this.removeButton?.addEventListener("click", this.onRemoveEntirely);
  }

  disconnect() {
    if (!this.dialog) return;

    this.keepButton?.removeEventListener("click", this.onKeepBookmarked);
    this.removeButton?.removeEventListener("click", this.onRemoveEntirely);
    Modal.getInstance(this.dialog)?.dispose();
    this.dialog.remove();
  }

  open() {
    Modal.getOrCreateInstance(this.dialog).show();
  }

  async confirm(keepBookmarked) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
    const url = `${this.urlValue}?keep_bookmarked=${keepBookmarked}`;

    const response = await fetch(url, {
      method: "DELETE",
      headers: {
        "Accept": "text/vnd.turbo-stream.html",
        "X-CSRF-Token": csrfToken,
      },
    });

    if (!response.ok) {
      console.error(`registration-notice-removal: failed (${response.status})`);
      Modal.getInstance(this.dialog)?.hide();
      return;
    }

    const html = await response.text();
    this.applyOnceHidden(() => {
      window.Turbo.renderStreamMessage(html);
      window.dispatchEvent(new CustomEvent("bookmark:changed", {
        detail: { lectureId: this.lectureIdValue, bookmarked: keepBookmarked },
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
