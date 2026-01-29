import { Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";

export default class extends Controller {
  static values = {
    url: String
  };

  connect() {
    this.sortable = Sortable.create(this.element, {
      handle: "[data-sortable-handle]",
      animation: 150,
      onEnd: this.updateOrder.bind(this)
    });
  }

  disconnect() {
    if (this.sortable) {
      this.sortable.destroy();
    }
  }

  async updateOrder() {
    const items = this.element.querySelectorAll("[data-sortable-item]");
    const order = Array.from(items).map((item) => item.dataset.id);

    this.updateIndexes(items);

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        },
        body: JSON.stringify({ order })
      });

      if (!response.ok) {
        throw new Error("Failed to update order");
      }
    }
    catch (error) {
      console.error("Error updating order:", error);
    }
  }

  updateIndexes(items) {
    Array.from(items).forEach((item, index) => {
      const indexEl = item.querySelector("[data-sortable-index]");
      if (!indexEl) {
        return;
      }
      indexEl.textContent = `${index + 1}.`;
      indexEl.classList.add("task-index-highlight");
      window.setTimeout(() => {
        indexEl.classList.remove("task-index-highlight");
      }, 600);
    });
  }
}
