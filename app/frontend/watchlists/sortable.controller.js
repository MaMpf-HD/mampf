import { Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";

export default class extends Controller {
  connect() {
    const id = document.getElementById("watchlistButton")?.dataset.id;
    const owned = document.getElementById("watchlistButton")?.dataset.owned;
    const sortableElement = this.element;

    if (owned !== "true" || !sortableElement) return;

    Sortable.create(sortableElement, {
      handle: ".mampf-card-header",
      animation: 150,
      onUpdate: () => this.updateOrder(id),
    });
  }

  updateOrder(id) {
    const params = new URLSearchParams(window.location.search);
    const order = Array.from(
      this.element.querySelectorAll(".media-grid"),
    ).map(el => el.dataset.id);

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content");

    fetch("/watchlists/rearrange", {
      method: "PATCH",
      headers: {
        "Accept": "text/html",
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
      },
      body: JSON.stringify({
        order,
        id,
        reverse: params.get("reverse") || "false",
        per: params.get("per") || "10",
        page: params.get("page") || "1",
      }),
    });
  }
}
