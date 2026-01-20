import { Controller } from "@hotwired/stimulus";
import { Tab, Collapse } from "bootstrap";

export default class extends Controller {
  static targets = ["tabButton"];

  connect() {
    this.tabButtonTargets.forEach((tabButton) => {
      tabButton.addEventListener("shown.bs.tab", this.onTabFocus);
    });

    document.addEventListener("click", this.handleHelpButtonClick.bind(this));
  }

  disconnect() {
    document.removeEventListener("click", this.handleHelpButtonClick.bind(this));
  }

  handleHelpButtonClick(event) {
    const helpButton = event.target.closest('[data-bs-toggle="collapse"]');
    if (!helpButton) return;

    const targetId = helpButton.getAttribute("href")
      || helpButton.getAttribute("data-bs-target");
    if (!targetId) return;

    const targetElement = document.querySelector(targetId);
    if (!targetElement) return;

    const tabPane = targetElement.closest(".tab-pane");
    if (!tabPane || tabPane.classList.contains("show")) return;

    const groupsTabButton = this.tabButtonTargets.find(
      btn => btn.dataset.tabName === "groups",
    );
    if (groupsTabButton) {
      event.preventDefault();
      const tab = Tab.getOrCreateInstance(groupsTabButton);
      tab.show();

      setTimeout(() => {
        const collapse = Collapse.getOrCreateInstance(targetElement);
        collapse.toggle();
      }, 150);
    }
  }

  onTabFocus(event) {
    const tabName = event.currentTarget.dataset.tabName;
    const url = new URL(window.location);
    url.searchParams.set("tab", tabName);

    history.replaceState({ turbo: true, url: url.toString() }, "", url.toString());
  }
}
