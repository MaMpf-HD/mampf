import { Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";

export default class extends Controller {
  static targets = ["form"];

  connect() {
    this.sortable = Sortable.create(this.element, {
      animation: 150,
      draggable: ".policy-badge",
      filter: ".policy-badge-actions, .policy-badge-action, .policy-add-link",
      preventOnFilter: false,
      onEnd: this.#reorder.bind(this),
    });
  }

  disconnect() {
    this.sortable?.destroy();
  }

  #reorder() {
    const form = this.formTarget;
    const container = form.querySelector("[data-ids]");
    container.innerHTML = "";

    this.element
      .querySelectorAll(".policy-badge[data-policy-id]")
      .forEach((el) => {
        const input = document.createElement("input");
        input.type = "hidden";
        input.name = "policy_ids[]";
        input.value = el.dataset.policyId;
        container.appendChild(input);
      });

    form.requestSubmit();
  }
}
