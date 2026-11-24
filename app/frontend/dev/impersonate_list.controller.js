import { Controller } from "@hotwired/stimulus";

/**
 * Dev-only user switcher: filters the users by the search term and lets
 * the down arrow jump from the search field to the first visible user.
 * From there on, Bootstrap's dropdown handles the arrow keys.
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
