import { Controller } from "@hotwired/stimulus";

/**
 * Handles Bootstrap tab navigation with URL hashes.
 */
export default class extends Controller {
  static targets = ["tabButton"];

  connect() {
    this.configureUrlHashesForBootstrapTabs();
  }

  configureUrlHashesForBootstrapTabs() {
    this.tabButtonTargets.forEach((tabButton) => {
      tabButton.addEventListener("shown.bs.tab", this.onTabFocus);
    });
  }

  onTabFocus(event) {
    const href = event.currentTarget.getAttribute("href"); // e.g. "#orga"
    const tabName = href.replace("#", "");
    const url = new URL(window.location);
    url.searchParams.set("tab", tabName);
    history.replaceState({ turbo: true, url: url.toString() }, "", url.toString());
  }
}
