import { Controller } from "@hotwired/stimulus";

const STORAGE_KEY = "mampf.sidebarCollapsed";

// The lecture sidebar is wide, and pages like the grading table need the room.
// The choice is the reader's, so it outlives the page: Turbo swaps the frame,
// not the layout, but a full reload would otherwise forget it.
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

    if (!this.hasToggleTarget) return;

    this.toggleTarget.setAttribute("aria-expanded", String(!collapsed));
    this.toggleTarget.querySelector("i").className = collapsed
      ? "bi bi-layout-sidebar"
      : "bi bi-layout-sidebar-inset";
  }
}
