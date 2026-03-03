import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";

export default class extends Controller {
  static targets = [
    "tile",
    "panelCard",
    "filterInput",
    "list",
    "noResults",
  ];

  activeTile = null;
  activeRosterKey = null;
  isOpen = false;

  connect() {
    this.close();
  }

  tileTargetConnected(tile) {
    if (!this.isOpen || !this.activeRosterKey) {
      return;
    }

    if (tile.dataset.rosterKey !== this.activeRosterKey) {
      return;
    }

    this.activateTile(tile);
  }

  openFromTile(event) {
    const clickInsideAction = event.target.closest(
      ".tutorial-gtile-actions, .tutorial-roster-student-remove, a, button, form",
    );

    if (clickInsideAction) {
      return;
    }

    const tile = event.currentTarget;
    const panelPath = tile?.dataset?.rosterPanelPath;
    if (!tile || !panelPath) {
      return;
    }

    if (this.isOpen && tile.dataset.rosterKey === this.activeRosterKey) {
      this.close();
      return;
    }

    this.activateTile(tile);
    this.openPanel();
    this.requestPanel(panelPath);
  }

  close() {
    this.isOpen = false;
    this.element.classList.remove("tutorial-roster-layout--open");
    this.element.classList.add("tutorial-roster-layout--closed");

    if (this.hasActiveTile()) {
      this.activeTile.classList.remove("tutorial-gtile--selected");
    }

    this.activeTile = null;
    this.activeRosterKey = null;
  }

  closeOnLeavingLanes(event) {
    const fromTarget = event.relatedTarget?.dataset?.bsTarget;
    const toTarget = event.target?.dataset?.bsTarget;

    if (fromTarget !== "#lanes-pane" || toTarget === "#lanes-pane") {
      return;
    }

    this.close();
  }

  hasActiveTile() {
    return this.activeTile && this.activeTile.classList;
  }

  openPanel() {
    this.isOpen = true;
    this.element.classList.add("tutorial-roster-layout--open");
    this.element.classList.remove("tutorial-roster-layout--closed");

    if (window.matchMedia("(max-width: 1399.98px)").matches) {
      this.panelCardTarget.scrollIntoView({ behavior: "smooth", block: "start" });
    }
  }

  filter() {
    if (!this.hasListTarget || !this.hasNoResultsTarget) {
      return;
    }

    const query = this.filterInputTarget.value.trim().toLowerCase();
    const rows = this.listTarget.querySelectorAll("[data-student-search]");
    let visibleCount = 0;

    rows.forEach((row) => {
      const haystack = row.dataset.studentSearch || "";
      const visible = query.length === 0 || haystack.includes(query);
      row.classList.toggle("d-none", !visible);
      if (visible) visibleCount += 1;
    });

    this.noResultsTarget.classList.toggle("d-none", visibleCount > 0);
  }

  activateTile(tile) {
    if (this.activeTile) {
      this.activeTile.classList.remove("tutorial-gtile--selected");
    }

    this.activeTile = tile;
    this.activeRosterKey = tile.dataset.rosterKey || null;
    this.activeTile.classList.add("tutorial-gtile--selected");
  }

  async requestPanel(panelPath) {
    const response = await fetch(panelPath, {
      headers: {
        "accept": "text/vnd.turbo-stream.html",
        "X-Requested-With": "XMLHttpRequest",
      },
      credentials: "same-origin",
    });

    if (!response.ok) {
      return;
    }

    const streamHtml = await response.text();
    Turbo.renderStreamMessage(streamHtml);
  }
}
