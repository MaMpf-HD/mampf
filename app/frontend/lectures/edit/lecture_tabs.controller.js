import { Controller } from "@hotwired/stimulus";

/**
 * Handles Bootstrap tab navigation with URL hashes.
 */
export default class extends Controller {
  static targets = ["tabButton"];

  connect() {
    this.configureUrlHashesForBootstrapTabs();
    this.navigateToActiveNavTab();
    window.addEventListener("hashchange", this.navigateToActiveNavTab);
  }

  disconnect() {
    window.removeEventListener("hashchange", this.navigateToActiveNavTab);
  }

  configureUrlHashesForBootstrapTabs() {
    this.tabButtonTargets.forEach((tabButton) => {
      tabButton.addEventListener("shown.bs.tab", this.onTabFocus);
    });
  }

  onTabFocus(event) {
    const hash = event.currentTarget.getAttribute("href");
    console.log(`Hash: ${hash}`);
    history.replaceState({ turbo: true, url: hash }, "", hash);
  };

  navigateToActiveNavTab() {
    let hash = location.hash;
    const navPills = document.getElementById("lecture-nav-pills");

    // Default page
    if (!hash) {
      hash = navPills.getAttribute("data-is-vignette-lecture") === "true"
        ? "#vignettes"
        : "#content";
      history.replaceState({ turbo: true, url: hash }, "", hash);
    }

    const tabButton = navPills.querySelector(`button[href='${hash}']`);
    $(tabButton).tab("show");
  };
}
