import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";

// Narrows the names in the menu for putting somebody on a team. The list
// keeps the height it opened with, so a menu opened above its button stays
// where it opened while the tutor types. Where teams may span tutorials, the
// members of the other tutorials are asked for as the tutor types: the page
// holds only the group's own.
export default class extends Controller {
  static targets = ["query", "list", "item", "empty", "results"];
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

  // Waits for a pause in the typing; a query too short to ask about takes
  // the others' names away again.
  searchElsewhere(query) {
    if (!this.urlValue) {
      return;
    }
    this.cancelSearch();
    if (this.hasResultsTarget) {
      this.resultsTarget.hidden = true;
    }
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
    }
    catch (error) {
      if (error.name === "AbortError") return;
    }
    this.pending = false;
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
  }

  cancelSearch() {
    clearTimeout(this.timer);
    this.request?.abort();
  }

  // Says nobody matches only once the other tutorials have answered too.
  showEmpty() {
    const results = this.hasResultsTarget && !this.resultsTarget.hidden
      ? Number(this.resultsTarget.dataset.count)
      : 0;
    this.emptyTarget.hidden = this.pending || this.shownHere + results > 0;
  }

  // Bootstrap leaves the arrow keys to a text field; down from it reaches
  // the names, and from there Bootstrap walks them as in any menu.
  enterList(event) {
    const first = [...this.listTarget.querySelectorAll(".dropdown-item")]
      .find(item => item.checkVisibility());
    if (!first) {
      return;
    }
    event.preventDefault();
    first.focus();
  }
}
