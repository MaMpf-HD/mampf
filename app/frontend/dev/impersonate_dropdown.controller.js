import { Controller } from "@hotwired/stimulus";

/**
 * The search field in the dropdown for switching the user, which only local
 * environments show.
 */
export default class extends Controller {
  static targets = ["search", "user"];

  /**
   * Puts the cursor into the search field when the dropdown opens. Bootstrap
   * shows the menu in the same click, and a field takes the focus only once it
   * is visible, hence the delay.
   */
  focusSearch() {
    setTimeout(() => this.searchTarget.focus(), 0);
  }

  /** Shows only the users whose name contains what the search field holds. */
  filter() {
    const query = this.searchTarget.value.toLowerCase();
    this.userTargets.forEach((user) => {
      user.hidden = !user.dataset.username.includes(query);
    });
  }
}
