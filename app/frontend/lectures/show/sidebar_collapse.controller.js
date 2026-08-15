import { Controller } from "@hotwired/stimulus";

const STORAGE_KEY = "mampf.sidebarCollapsed";

// The lecture sidebar is wide, and pages like the grading table need the room.
// Collapsed it becomes a rail of icons. The choice is the reader's, so it
// outlives the page: Turbo swaps the frame, not the layout, but a full reload
// would otherwise forget it.
export default class extends Controller {
  static targets = ["toggle"];
  static classes = ["collapsed"];

  connect() {
    this.apply(localStorage.getItem(STORAGE_KEY) === "true");
  }

  toggle() {
    this.apply(!this.element.classList.contains(this.collapsedClass));
  }

  apply(collapsed) {
    this.element.classList.toggle(this.collapsedClass, collapsed);
    localStorage.setItem(STORAGE_KEY, collapsed);
    this.nameIcons(collapsed);

    if (!this.hasToggleTarget) return;

    this.toggleTarget.setAttribute("aria-expanded", String(!collapsed));
    this.toggleTarget.querySelector("i").className = collapsed
      ? "bi bi-layout-sidebar"
      : "bi bi-layout-sidebar-inset";
  }

  // On the rail the label is only there for screen readers, so sighted readers
  // need the name on hover instead.
  nameIcons(collapsed) {
    this.element.querySelectorAll(".sidebar-item a").forEach((link) => {
      const label = link.querySelector(".sidebar-item__text");
      if (!label) return;

      if (collapsed) {
        link.setAttribute("title", label.textContent.trim());
      }
      else {
        link.removeAttribute("title");
      }
    });
  }
}
