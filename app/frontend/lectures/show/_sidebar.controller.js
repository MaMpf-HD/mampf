// adapted from https://stackoverflow.com/a/76836412/9655481

import { Controller } from "@hotwired/stimulus";

const ACTIVE_ITEM_CSS_CLASS = "active-item";

export default class extends Controller {
  connect() {
    this.active_link = null;
  }

  disconnect() {
    this.active_link = null;
  }

  /**
   * Sets the active link in the sidebar when clicked, but not on the initial
   * page load.
   */
  setActive(event) {
    this.activate(event.currentTarget);
  }

  /**
   * Marks the entry of the page the main frame has loaded, so that a page
   * reached from a link in the content marks its entry as a click on the
   * entry itself does.
   */
  markLoaded(event) {
    if (event.target.id !== "main" || !event.target.src) return;

    const path = new URL(event.target.src, window.location.href).pathname;
    const link = [...this.element.querySelectorAll(".sidebar-item a[href]")]
      .find(candidate => new URL(candidate.href).pathname === path);
    if (link) this.activate(link);
  }

  activate(link) {
    this.removeActiveStyling();
    this.removeIconFill();
    this.setActiveLink(link);
    this.fillActiveIcon();
  }

  removeActiveStyling() {
    const navLinks = document.querySelectorAll(".sidebar-item");
    navLinks.forEach((link) => {
      link.classList.remove(ACTIVE_ITEM_CSS_CLASS);
    });
  }

  removeIconFill() {
    const icons = document.querySelectorAll(".sidebar-item i");
    icons.forEach((icon) => {
      const classList = icon.classList;
      const lastClass = classList[classList.length - 1];
      if (lastClass.endsWith("-fill")) {
        classList.remove(lastClass);
        classList.add(lastClass.replace(/-fill$/, ""));
      }
    });
  }

  setActiveLink(link) {
    this.active_link = link.closest("li");
    this.active_link.classList.add(ACTIVE_ITEM_CSS_CLASS);
  }

  fillActiveIcon() {
    const icon = this.active_link.querySelector("i");
    if (!icon) return;

    const classList = icon.classList;
    const lastClass = classList[classList.length - 1];
    if (!lastClass.endsWith("-fill")) {
      classList.remove(lastClass);
      classList.add(lastClass + "-fill");
    }
  }
}
