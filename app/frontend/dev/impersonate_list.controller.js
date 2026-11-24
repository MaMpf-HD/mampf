import { Controller } from "@hotwired/stimulus";

/**
 * User switcher (dev-only) including a filter.
 */
export default class extends Controller {
  static targets = ["search", "user"];

  filter() {
    const query = this.searchTarget.value.toLowerCase();
    this.userTargets.forEach((li) => {
      li.hidden = !li.dataset.username.includes(query);
    });
  }

  focusFirstUser() {
    this.userTargets.find(li => !li.hidden)?.querySelector("button").focus();
  }
}
