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
    this.removeActiveStyling();
    this.removeIconFill();
    this.setActiveLink(event);
    this.fillActiveIcon();
  }

  removeActiveStyling() {
    const navLinks = document.querySelectorAll(".nav-link");
    navLinks.forEach((link) => {
      link.classList.remove(ACTIVE_ITEM_CSS_CLASS);
    });
  }

  removeIconFill() {
    const icons = document.querySelectorAll(".nav-link i");
    icons.forEach((icon) => {
      const classList = icon.classList;
      const lastClass = classList[classList.length - 1];
      if (lastClass.endsWith("-fill")) {
        classList.remove(lastClass);
        classList.add(lastClass.replace(/-fill$/, ""));
      }
    });
  }

  setActiveLink(event) {
    this.active_link = event.target.closest("li");
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
