import { Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";

export default class extends Controller {
  connect() {
    const id = document.getElementById("watchlistButton")?.dataset.id;
    const owned = document.getElementById("watchlistButton")?.dataset.owned;
    const sortableElement = this.element;

    if (!owned || !sortableElement) return;

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

    console.log("Order to send:", order);

    const queryParams = new URLSearchParams({
      order: JSON.stringify(order),
      id,
      reverse: params.get("reverse") || "false",
      per: params.get("per") || "10",
      page: params.get("page") || "1",
    });

    fetch(`/watchlists/rearrange?${queryParams.toString()}`, {
      method: "GET",
      headers: {
        Accept: "text/html",
      },
    });
  }
}
