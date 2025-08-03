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

  setActive(event) {
    const navLinks = document.querySelectorAll(".nav-link");
    navLinks.forEach((link) => {
      link.classList.remove(ACTIVE_ITEM_CSS_CLASS);
    });

    this.active_link = event.target.closest("li");
    this.active_link.classList.add(ACTIVE_ITEM_CSS_CLASS);
  }
}
