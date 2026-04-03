import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    confirmMessage: String,
    warningMessage: String,
    campaignId: String,
  };

  confirmed = false;

  async submit(event) {
    if (this.confirmed) {
      return;
    }

    event.preventDefault();

    let message = this.confirmMessageValue;

    try {
      const response = await fetch(
        `/campaigns/${this.campaignIdValue}/check_unlimited_items`,
        { headers: { Accept: "application/json" } },
      );

      if (response.ok) {
        const data = await response.json();
        if (data.has_unlimited_items) {
          message += "\n\n" + this.warningMessageValue;
        }
      }
    }
    catch {
      // Proceed without the warning
    }

    if (!confirm(message)) {
      return;
    }

    const card = this.element.closest(".registration-campaign-card");
    if (!card) {
      this.confirmed = true;
      this.element.requestSubmit();
      return;
    }

    const submitForm = () => {
      this.confirmed = true;
      this.element.requestSubmit();
    };

    card.classList.add("campaign-dissolving");

    const reduced = window.matchMedia(
      "(prefers-reduced-motion: reduce)",
    ).matches;

    if (reduced) {
      submitForm();
    }
    else {
      card.addEventListener("animationend", submitForm, { once: true });
    }
  }
}
