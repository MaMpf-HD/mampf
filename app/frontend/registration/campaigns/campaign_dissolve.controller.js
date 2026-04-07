import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  submit(event) {
    if (this.confirmed) return; // base condition to prevent loops

    // Pause the form submission that Turbo is about to process.
    // data-turbo-confirm has already asked the user at this point.
    event.preventDefault();

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
