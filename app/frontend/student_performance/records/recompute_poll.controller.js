import { Controller } from "@hotwired/stimulus";

export default class RecomputePollController extends Controller {
  static values = {
    statusUrl: String,
    reloadUrl: String,
    interval: { type: Number, default: 3000 },
  };

  connect() {
    this._polling = false;
  }

  disconnect() {
    this.stopPolling();
  }

  start() {
    if (this._polling) return;

    this._since = new Date().toISOString();
    this._polling = true;
    this.element.querySelector("[data-recompute-poll-target='indicator']")
      ?.classList.remove("d-none");
    this.poll();
  }

  async poll() {
    if (!this._polling) return;

    try {
      const url = new URL(this.statusUrlValue, window.location.origin);
      url.searchParams.set("since", this._since);

      const response = await fetch(url, {
        headers: { Accept: "application/json" },
      });
      const data = await response.json();

      if (data.done) {
        this.stopPolling();
        this.reloadFrame();
        return;
      }
    }
    catch {
      // noop
    }

    this._timer = setTimeout(() => this.poll(), this.intervalValue);
  }

  stopPolling() {
    this._polling = false;
    if (this._timer) {
      clearTimeout(this._timer);
      this._timer = null;
    }
    this.element.querySelector("[data-recompute-poll-target='indicator']")
      ?.classList.add("d-none");
  }

  reloadFrame() {
    const frame = document.querySelector(
      "turbo-frame#performance-records-frame",
    );
    if (frame) {
      frame.src = this.reloadUrlValue || window.location.href;
    }
    else {
      window.location.reload();
    }
  }
}
