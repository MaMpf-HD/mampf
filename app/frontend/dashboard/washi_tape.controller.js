import { Controller } from "@hotwired/stimulus";
import { sendDashboardRequest } from "./dashboard_request";

/** Opens the color picker for a dashboard card's washi tape and saves a choice. */
export default class extends Controller {
  static targets = ["strip", "picker"];
  static values = { url: String };

  connect() {
    this.card = this.element.closest(".dashboard-card");
    this.savedColor = this.pickerTarget.querySelector("input:checked")?.value;
    this.closeOnOutsideClick = (event) => {
      if (!this.element.contains(event.target)) this.close();
    };
    this.closeOnEscape = (event) => {
      if (event.key === "Escape") {
        this.close();
        this.stripTarget.focus();
      }
    };
  }

  disconnect() {
    this.close();
  }

  toggle() {
    if (this.pickerTarget.hidden) this.open();
    else this.close();
  }

  open() {
    this.pickerTarget.hidden = false;
    this.stripTarget.setAttribute("aria-expanded", "true");
    // capture, so a click on another card's strip closes this picker before
    // that strip's own toggle runs and would immediately close the new one
    document.addEventListener("click", this.closeOnOutsideClick, true);
    document.addEventListener("keydown", this.closeOnEscape);
  }

  close() {
    if (this.pickerTarget.hidden) return;

    this.pickerTarget.hidden = true;
    this.stripTarget.setAttribute("aria-expanded", "false");
    document.removeEventListener("click", this.closeOnOutsideClick, true);
    document.removeEventListener("keydown", this.closeOnEscape);
  }

  chooseColor(event) {
    const color = event.target.value;
    this.paint(color);
    this.save(color);
  }

  paint(color) {
    this.card?.style.setProperty("--washi-tape-color",
      `var(--washi-tape-color-${color})`);
  }

  /**
   * Puts the saved color back when the server refuses the new one, so the
   * card does not show a color that is gone after a reload.
   */
  async save(color) {
    const response = await sendDashboardRequest(this.urlValue, "PATCH",
      { washi_tape: { tape_color: color } });

    if (response.ok) {
      this.savedColor = color;
      return;
    }

    console.error(`washi-tape: the color was not saved (${response.status})`);
    if (!this.savedColor) return;

    this.paint(this.savedColor);
    const saved = this.pickerTarget.querySelector(`input[value="${this.savedColor}"]`);
    if (saved) saved.checked = true;
  }
}
