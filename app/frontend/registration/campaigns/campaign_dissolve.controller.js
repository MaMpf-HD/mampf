import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    confirmMessage: String,
  };

  submit(event) {
    if (this.confirmed) {
      this.confirmed = false;
      return;
    }

    const card = this.element.closest(".registration-campaign-card");

    if (!card) {
      if (!confirm(this.confirmMessageValue)) {
        event.preventDefault();
      }
      return;
    }

    event.preventDefault();

    if (!confirm(this.confirmMessageValue)) return;

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
