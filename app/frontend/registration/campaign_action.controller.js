import CampaignConfirmBase from "./campaign_confirm_base.controller";

export default class extends CampaignConfirmBase {
  async confirm(event) {
    if (this.confirmed) return;

    event.preventDefault();

    const message = await this.buildMessage();

    if (confirm(message)) {
      this.submitForm();
    }
  }
}
