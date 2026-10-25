import { Controller } from "@hotwired/stimulus";

// Narrows the names in the menu for putting somebody on a team. The list
// keeps the height it opened with, so a menu opened above its button stays
// where it opened while the tutor types.
export default class extends Controller {
  static targets = ["query", "list", "item", "empty"];

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
    const query = this.queryTarget.value.trim().toLowerCase();
    let shown = 0;
    this.itemTargets.forEach((item) => {
      item.hidden = !item.dataset.addMemberMenuName.toLowerCase().includes(query);
      if (!item.hidden) shown += 1;
    });
    this.emptyTarget.hidden = shown > 0;
  }

  // Bootstrap leaves the arrow keys to a text field; down from it reaches
  // the names, and from there Bootstrap walks them as in any menu.
  enterList(event) {
    const first = this.itemTargets.find(item => !item.hidden);
    if (!first) {
      return;
    }
    event.preventDefault();
    first.querySelector(".dropdown-item").focus();
  }
}
