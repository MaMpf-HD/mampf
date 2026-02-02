import { Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";

export default class extends Controller {
  static values = {
    url: String,
  };

  connect() {
    this.sortable = Sortable.create(this.element, {
      handle: "[data-sortable-handle]",
      animation: 150,
      onEnd: this.handleDragEnd.bind(this),
    });
  }

  disconnect() {
    if (this.sortable) {
      this.sortable.destroy();
    }
  }

  async handleDragEnd(event) {
    const items = this.element.querySelectorAll("[data-sortable-item]");
    this.updateIndexes(items);

    const taskId = event.item.dataset.id;
    const newPosition = event.newIndex + 1;

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
        },
        body: JSON.stringify({ task_id: taskId, position: newPosition }),
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
