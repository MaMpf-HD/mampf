import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "tile",
    "main",
    "panelShell",
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
  currentSection = null;

  connect() {
    this.boundSyncPanelToSection = this.syncPanelToSection.bind(this);
    this.boundCloseOnEscape = this.closeOnEscape.bind(this);
    window.addEventListener("scroll", this.boundSyncPanelToSection, { passive: true });
    window.addEventListener("resize", this.boundSyncPanelToSection);
    document.addEventListener("keydown", this.boundCloseOnEscape);
    this.close();
  }

  disconnect() {
    window.removeEventListener("scroll", this.boundSyncPanelToSection);
    window.removeEventListener("resize", this.boundSyncPanelToSection);
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
    this.currentSection = tile.closest(".campaign-section, section");
    this.openPanel();
    this.renderPanel(tile.dataset);
    this.syncPanelToSection();
  }

  close() {
    this.isOpen = false;
    this.element.classList.remove("tutorial-roster-layout--open");
    this.element.classList.add("tutorial-roster-layout--closed");

    if (this.hasActiveTile()) {
      this.activeTile.classList.remove("tutorial-gtile--selected");
    }

    this.activeTile = null;
    this.currentSection = null;
    this.resetPanelPosition();
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

    this.countBadgeTarget.textContent = `${visibleCount} / ${this.totalCount} students`;
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

  syncPanelToSection() {
    if (!this.isOpen || window.matchMedia("(max-width: 1399.98px)").matches) {
      this.resetPanelPosition();
      return;
    }

    const section = this.visibleSection();
    if (!section) {
      return;
    }

    const layoutRect = this.element.getBoundingClientRect();
    const sectionRect = section.getBoundingClientRect();
    const offsetTop = Math.max(0, sectionRect.top - layoutRect.top);
    const panelHeight = Math.max(320, Math.min(sectionRect.height, window.innerHeight - 130));

    this.panelShellTarget.style.marginTop = `${offsetTop}px`;
    this.panelCardTarget.style.height = `${panelHeight}px`;
  }

  visibleSection() {
    const sections = Array.from(
      this.mainTarget.querySelectorAll(".campaign-section, section"),
    ).filter(section => section.offsetParent !== null);

    if (sections.length === 0) {
      return this.currentSection;
    }

    const viewportAnchor = window.innerHeight * 0.32;
    let bestSection = sections[0];
    let bestDistance = Number.POSITIVE_INFINITY;

    sections.forEach((section) => {
      const rect = section.getBoundingClientRect();
      const sectionAnchor = rect.top + Math.min(rect.height * 0.35, 180);
      const distance = Math.abs(sectionAnchor - viewportAnchor);

      if (distance < bestDistance) {
        bestDistance = distance;
        bestSection = section;
      }
    });

    return bestSection;
  }

  resetPanelPosition() {
    if (!this.hasPanelShellTarget || !this.hasPanelCardTarget) {
      return;
    }

    this.panelShellTarget.style.marginTop = "";
    this.panelCardTarget.style.height = "";
  }
}
