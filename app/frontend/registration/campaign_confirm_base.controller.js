import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    confirmMessage: String,
    warningMessage: String,
    campaignId: String,
  };

  confirmed = false;

  connect() {
    this.confirmed = false;
  }

  async buildMessage() {
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

    return message;
  }

  submitForm() {
    this.confirmed = true;
    this.element.requestSubmit();
  }
}
