import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    confirmMessage: String,
  };

  submit(event) {
    if (this.confirmed) return; // base condition to prevent loops

    event.preventDefault();

    if (!confirm(this.confirmMessageValue)) return;

    const card = this.element.closest(".registration-campaign-card");
    if (!card) {
      this.resume();
      return;
    }

    card.classList.add("campaign-dissolving");

    const reduced = window.matchMedia(
      "(prefers-reduced-motion: reduce)",
    ).matches;

    if (reduced) {
      this.resume();
    }
    else {
      card.addEventListener(
        "animationend", () => this.resume(), { once: true },
      );
    }
  }

  resume() {
    this.confirmed = true;
    this.element.requestSubmit();
  }
}
