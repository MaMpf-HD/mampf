import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "tile",
    "main",
    "panelCard",
    "emptyState",
    "contentState",
    "metaLine",
    "title",
    "tutorNames",
    "countBadge",
    "addForm",
    "addEmailInput",
    "filterInput",
    "list",
    "noResults",
  ];

  activeTile = null;
  totalCount = 0;
  isOpen = false;

  connect() {
    this.boundCloseOnEscape = this.closeOnEscape.bind(this);
    document.addEventListener("keydown", this.boundCloseOnEscape);
    this.close();
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundCloseOnEscape);
  }

  openFromTile(event) {
    const clickInsideAction = event.target.closest(
      ".tutorial-gtile-actions, .tutorial-roster-student-remove, a, button, form",
    );

    if (clickInsideAction) {
      return;
    }

    const tile = event.currentTarget;
    if (!tile || !tile.dataset.rosterTemplateId) {
      return;
    }

    this.activateTile(tile);
    this.openPanel();
    this.renderPanel(tile.dataset);
  }

  close() {
    this.isOpen = false;
    this.element.classList.remove("tutorial-roster-layout--open");
    this.element.classList.add("tutorial-roster-layout--closed");

    if (this.hasActiveTile()) {
      this.activeTile.classList.remove("tutorial-gtile--selected");
    }

    this.activeTile = null;
  }

  closeOnEscape(event) {
    if (event.key !== "Escape" || !this.isOpen) {
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
    this.activeTile.classList.add("tutorial-gtile--selected");
  }

  renderPanel(data) {
    const template = document.getElementById(data.rosterTemplateId);
    this.totalCount = Number.parseInt(data.rosterStudentsCount || "0", 10) || 0;

    this.titleTarget.textContent = data.rosterTitle || "—";
    this.tutorNamesTarget.textContent = data.rosterTutors || "—";
    this.countBadgeTarget.textContent = `${this.totalCount} students`;

    this.metaLineTarget.classList.remove("d-none");
    this.emptyStateTarget.classList.add("d-none");
    this.contentStateTarget.classList.remove("d-none");

    this.listTarget.innerHTML = template ? template.innerHTML : "";
    this.noResultsTarget.classList.add("d-none");
    this.filterInputTarget.value = "";

    const addPath = data.rosterAddMemberPath || "#";
    this.addFormTarget.action = addPath;
    this.addEmailInputTarget.value = "";

    this.filter();
  }
}
