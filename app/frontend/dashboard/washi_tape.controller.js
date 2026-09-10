import { Controller } from "@hotwired/stimulus";

/**
 * The washi tape strip on a dashboard card: opens the picker for its color,
 * applies a choice straight away and saves it for this user.
 *
 * The color is set on the card rather than the strip, because the card's
 * border is dyed in it too. Updating it locally rather than re-rendering keeps
 * picking instant; a request that fails only costs the saved preference, and
 * the card shows the stored color again on the next load.
 */
export default class extends Controller {
  static targets = ["strip", "picker"];
  static values = { url: String };

  connect() {
    this.card = this.element.closest(".dashboard-card");
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
    this.card?.style.setProperty("--washi-tape-color",
      `var(--washi-tape-color-${color})`);
    this.save(color);
  }

  async save(color) {
    // absent where forgery protection is off, e.g. the test environment
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;

    const response = await fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
      },
      body: JSON.stringify({ washi_tape: { tape_color: color } }),
    });

    if (!response.ok) {
      console.error(`washi-tape: the color was not saved (${response.status})`);
    }
  }
}
