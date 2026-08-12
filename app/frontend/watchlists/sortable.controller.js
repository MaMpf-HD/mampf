import { Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";

export default class extends Controller {
  static values = {
    watchlistId: Number,
    // Convenience only — WatchlistsController#update_order authorizes as well.
    owned: Boolean,
  };

  connect() {
    if (!this.ownedValue) return;

    Sortable.create(this.element, {
      handle: ".mampf-card-header",
      animation: 150,
      onUpdate: () => this.queueOrder(),
    });
  }

  /**
   * Two quick drops must not race: the second order would be persisted first
   * and then overwritten by the first one arriving late.
   */
  queueOrder() {
    this.pending = (this.pending ?? Promise.resolve()).then(() => this.sendOrder());
    return this.pending;
  }

  async sendOrder() {
    const params = new URLSearchParams(window.location.search);
    const order = Array.from(
      this.element.querySelectorAll(".media-grid"),
    ).map(el => el.dataset.id);

    // absent where forgery protection is off, e.g. the test environment
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;

    const response = await fetch("/watchlists/rearrange", {
      method: "PATCH",
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
      },
      body: JSON.stringify({
        order,
        id: this.watchlistIdValue,
        reverse: params.get("reverse") || "false",
        per: params.get("per") || "10",
        page: params.get("page") || "1",
      }),
    });

    if (!response.ok) {
      console.error(`watchlist-sortable: the new order was not saved (${response.status})`);
    }
  }
}
