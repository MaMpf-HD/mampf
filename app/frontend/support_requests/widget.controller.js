import { Controller } from "@hotwired/stimulus";

/**
 * Opens and closes the support panel above its button. The panel does not
 * block the page, so a click anywhere else closes it, as Escape does, and the
 * focus goes back to the button.
 */
export default class extends Controller {
  static targets = ["panel", "toggle", "message", "page"];

  connect() {
    this.closeOnOutsideClick = (event) => {
      if (!this.panelTarget.hidden && !this.element.contains(event.target)) {
        this.close();
      }
    };
    document.addEventListener("click", this.closeOnOutsideClick);
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnOutsideClick);
  }

  toggle() {
    if (this.panelTarget.hidden) {
      this.open();
    }
    else {
      this.close();
    }
  }

  open() {
    this.panelTarget.hidden = false;
    this.toggleTarget.setAttribute("aria-expanded", "true");
    if (this.hasMessageTarget) this.messageTarget.focus();
  }

  close() {
    if (this.panelTarget.hidden) return;

    this.panelTarget.hidden = true;
    this.toggleTarget.setAttribute("aria-expanded", "false");
    this.toggleTarget.focus();
  }

  /**
   * Tells the team which page the message was written on. Read at sending
   * time, since the lecture pages change their address without a new page.
   */
  stampPage() {
    if (this.hasPageTarget) this.pageTarget.value = window.location.href;
  }
}
