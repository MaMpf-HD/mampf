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

  async confirm(event) {
    // If already confirmed, allow the form to submit
    if (this.confirmed) {
      return;
    }

    event.preventDefault();

    let message = this.confirmMessageValue;

    // Check if there are any items with unlimited capacity
    try {
      const response = await fetch(
        `/campaigns/${this.campaignIdValue}/check_unlimited_items`,
        {
          headers: {
            Accept: "application/json",
          },
        },
      );

      if (response.ok) {
        const data = await response.json();
        if (data.has_unlimited_items) {
          message += "\n\n" + this.warningMessageValue;
        }
      }
    }
    catch (error) {
      console.error("Failed to check unlimited items:", error);
    }

    if (confirm(message)) {
      // Set flag and submit the form
      this.confirmed = true;
      this.element.requestSubmit();
    }
  }
}
