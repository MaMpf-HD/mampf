import { Controller } from "@hotwired/stimulus";

/**
 * Opens and closes the support panel above its button. The panel does not
 * block the page: a click elsewhere closes it, and Escape or the close button
 * also return the focus to the button.
 */
export default class extends Controller {
  static targets = ["panel", "toggle", "email", "message", "page", "result", "form"];

  connect() {
    this.closeOnOutsideClick = (event) => {
      if (!this.panelTarget.hidden && !this.element.contains(event.target)) {
        this.hide();
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
    this.firstField()?.focus();
  }

  close() {
    if (this.panelTarget.hidden) return;

    this.hide();
    this.toggleTarget.focus();
  }

  hide() {
    this.panelTarget.hidden = true;
    this.toggleTarget.setAttribute("aria-expanded", "false");
  }

  /**
   * Keeps the focus in the panel once the answer replaces the Send button, so
   * that Escape still works and a screen reader reads the result.
   */
  resultTargetConnected(element) {
    element.focus();
  }

  /**
   * Moves the focus to the invalid field of a returned form. The form on page
   * load also connects, but its panel is still hidden.
   */
  formTargetConnected(form) {
    if (this.panelTarget.hidden) return;

    (form.querySelector(".is-invalid") || this.firstField())?.focus();
  }

  firstField() {
    if (this.hasEmailTarget) return this.emailTarget;
    return this.hasMessageTarget ? this.messageTarget : null;
  }

  /**
   * Records the URL at submit time: lecture pages change it through the main
   * turbo frame, which keeps this widget.
   */
  stampPage() {
    if (this.hasPageTarget) this.pageTarget.value = window.location.href;
  }
}
