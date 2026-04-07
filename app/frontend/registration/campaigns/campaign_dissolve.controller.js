import CampaignConfirmBase from "../campaign_confirm_base.controller";

export default class extends CampaignConfirmBase {
  async submit(event) {
    if (this.confirmed) return;

    event.preventDefault();

    const message = await this.buildMessage();

    if (!confirm(message)) return;

    const card = this.element.closest(".registration-campaign-card");
    if (!card) {
      this.submitForm();
      return;
    }

    card.classList.add("campaign-dissolving");

    const reduced = window.matchMedia(
      "(prefers-reduced-motion: reduce)",
    ).matches;

    if (reduced) {
      this.submitForm();
    }
    else {
      card.addEventListener(
        "animationend", () => this.submitForm(), { once: true },
      );
    }
  }
}
