import { Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";

export default class extends Controller {
  static values = {
    url: String,
    errorMessage: String,
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
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content,
        },
        body: JSON.stringify({ task_id: taskId, position: newPosition }),
      });

      if (!response.ok) {
        throw new Error("Failed to update order");
      }
    }
    catch (error) {
      console.error("Error updating order:", error);
      this.putBack(event);
      this.reportFailure();
    }
  }

  // The new order is on screen before it is saved, so a save that did not
  // happen has to take the card back to where it was picked up.
  putBack(event) {
    const others = Array.from(this.element.querySelectorAll("[data-sortable-item]"))
      .filter(item => item !== event.item);

    this.element.insertBefore(event.item, others[event.oldIndex] || null);
    this.updateIndexes(this.element.querySelectorAll("[data-sortable-item]"));
  }

  reportFailure() {
    const container = document.getElementById("flash-messages");
    if (!container) {
      return;
    }

    const alert = document.createElement("div");
    alert.className = "alert alert-danger";
    alert.setAttribute("role", "alert");
    alert.textContent = this.errorMessageValue;
    container.prepend(alert);
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
