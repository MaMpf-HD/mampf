import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    confirmMessage: String,
    warningMessage: String,
    campaignId: String
  };

  async confirm(event) {
    event.preventDefault();

    let message = this.confirmMessageValue;

    // Check if there are any items with unlimited capacity
    try {
      const response = await fetch(
        `/campaigns/${this.campaignIdValue}/check_unlimited_items`,
        {
          headers: {
            Accept: "application/json"
          }
        }
      );

      if (response.ok) {
        const data = await response.json();
        if (data.has_unlimited_items) {
          message += "\n\n" + this.warningMessageValue;
        }
      }
    } catch (error) {
      console.error("Failed to check unlimited items:", error);
    }

    if (confirm(message)) {
      // Remove the data-action to prevent infinite loop, then click the button
      this.element.removeAttribute("data-action");
      this.element.click();
    }
  }
}
