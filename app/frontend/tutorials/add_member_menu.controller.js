import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";
import { Dropdown } from "bootstrap";

// Narrows the names in the menu for putting somebody on a team. The list
// keeps the height it opened with, so a menu opened above its button stays
// where it opened while the tutor types. Where teams may span tutorials, the
// members of the other tutorials are asked for as the tutor types: the page
// holds only the group's own.
export default class extends Controller {
  static targets = ["query", "list", "item", "empty", "failed", "results"];
  static values = { url: String, minLength: Number };

  disconnect() {
    this.cancelSearch();
  }

  open() {
    if (!this.hasQueryTarget) {
      return;
    }
    this.listTarget.style.minHeight = `${this.listTarget.offsetHeight}px`;
    this.queryTarget.focus();
  }

  close() {
    if (!this.hasQueryTarget) {
      return;
    }
    this.listTarget.style.minHeight = "";
    this.queryTarget.value = "";
    this.filter();
  }

  filter() {
    const query = this.queryTarget.value.trim();
    this.shownHere = 0;
    this.itemTargets.forEach((item) => {
      item.hidden = !item.dataset.addMemberMenuName.toLowerCase()
        .includes(query.toLowerCase());
      if (!item.hidden) this.shownHere += 1;
    });
    this.searchElsewhere(query);
    this.showEmpty();
  }

  // Asks only after a pause in the typing; a query shorter than the minimum
  // hides the other tutorials' results again.
  searchElsewhere(query) {
    if (!this.urlValue) {
      return;
    }
    this.cancelSearch();
    if (this.hasResultsTarget) {
      this.resultsTarget.hidden = true;
    }
    this.failed = false;
    this.pending = query.length >= this.minLengthValue;
    if (this.pending) {
      this.timer = setTimeout(() => this.fetchElsewhere(query), 250);
    }
  }

  async fetchElsewhere(query) {
    this.request = new AbortController();
    const url = new URL(this.urlValue, window.location.origin);
    url.searchParams.set("q", query);
    try {
      const response = await fetch(url, {
        headers: {
          "accept": "text/vnd.turbo-stream.html",
          "X-Requested-With": "XMLHttpRequest",
        },
        credentials: "same-origin",
        signal: this.request.signal,
      });
      if (response.ok) {
        Turbo.renderStreamMessage(await response.text());
        return;
      }
      console.warn(`Searching the other tutorials failed with ${response.status}`);
    }
    catch (error) {
      if (error.name === "AbortError") return;
      console.warn("Searching the other tutorials failed", error);
    }
    this.pending = false;
    this.failed = true;
    this.showEmpty();
  }

  // An answer to a query since replaced stays hidden; the newer one follows.
  resultsTargetConnected(results) {
    if (!this.hasQueryTarget || results.dataset.query !== this.queryTarget.value.trim()) {
      results.hidden = true;
      return;
    }
    this.pending = false;
    this.showEmpty();
    Dropdown.getInstance(this.element.querySelector("[data-bs-toggle='dropdown']"))?.update();
  }

  cancelSearch() {
    clearTimeout(this.timer);
    this.request?.abort();
  }

  // Says nobody matches only once the other tutorials have answered too, and
  // says so when they could not be asked rather than that nobody matches.
  showEmpty() {
    const results = this.hasResultsTarget && !this.resultsTarget.hidden
      ? Number(this.resultsTarget.dataset.count)
      : 0;
    if (this.hasFailedTarget) {
      this.failedTarget.hidden = !this.failed;
    }
    this.emptyTarget.hidden = this.failed || this.pending || this.shownHere + results > 0;
  }

  // Bootstrap leaves the arrow keys to a text field; down from it reaches
  // the names, and from there Bootstrap walks them as in any menu. Not
  // checkVisibility(): Safari has it only since 17.4.
  enterList(event) {
    const first = [...this.listTarget.querySelectorAll(".dropdown-item")]
      .find(item => item.getClientRects().length > 0);
    if (!first) {
      return;
    }
    event.preventDefault();
    first.focus();
  }
}
