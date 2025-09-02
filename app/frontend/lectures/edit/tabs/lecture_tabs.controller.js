import { Controller } from "@hotwired/stimulus";

/**
 * Handles Bootstrap tab navigation with URL hashes.
 */
export default class extends Controller {
  static targets = ["tabButton"];

  connect() {
    this.tabButtonTargets.forEach((tabButton) => {
      tabButton.addEventListener("shown.bs.tab", this.onTabFocus);
    });
  }

  onTabFocus(event) {
    const tabName = event.currentTarget.dataset.tabName;
    const url = new URL(window.location);
    // keep in sync with controller params[:subpage] handling in LecturesController
    url.searchParams.set("tab", tabName);

    history.replaceState({ turbo: true, url: url.toString() }, "", url.toString());
  }
}
