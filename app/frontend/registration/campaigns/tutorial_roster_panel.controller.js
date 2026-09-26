import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";

const SELECTED = "roster-trigger--selected";

/**
 * Opens a roster in the side panel from its trigger: a group row, a row of
 * the allocation table or a campaign's rejected/unassigned pill.
 */
export default class extends Controller {
  static targets = [
    "trigger",
    "panelShell",
    "panelCard",
    "filterInput",
    "list",
    "noResults",
  ];

  activeTrigger = null;
  activeRosterKey = null;
  isOpen = false;
  lecturePaneElement = null;
  focusedRosterKey = null;
  focusPanelOnLoad = false;

  connect() {
    this.lecturePaneElement = this.element.querySelector(".lecture-pane");
    this.close();
  }

  triggerTargetConnected(trigger) {
    const params = new URLSearchParams(window.location.search);
    const openRoster = params.get("open_roster");

    if (openRoster && trigger.dataset.rosterKey === openRoster && trigger.dataset.rosterPanelPath) {
      this.activate(trigger);
      this.openPanel();
      this.requestPanel(trigger.dataset.rosterPanelPath);

      params.delete("open_roster");
      const newSearch = params.toString();
      const newUrl = window.location.pathname + (newSearch ? "?" + newSearch : "") + window.location.hash;
      window.history.replaceState({}, "", newUrl);
      return;
    }

    this.restoreFocus(trigger);

    if (!this.isOpen || !this.activeRosterKey) {
      return;
    }

    if (trigger.dataset.rosterKey !== this.activeRosterKey) {
      return;
    }

    this.activate(trigger);
  }

  triggerTargetDisconnected(trigger) {
    if (trigger !== this.activeTrigger) {
      return;
    }

    const rosterKey = this.activeRosterKey;
    this.activeTrigger = null;

    requestAnimationFrame(() => {
      if (!this.isOpen || !rosterKey) {
        return;
      }

      const replacement = this.triggerTargets.find(
        candidate => candidate.dataset.rosterKey === rosterKey,
      );

      if (replacement) {
        this.activate(replacement);
        return;
      }

      this.close();
    });
  }

  /**
   * A click anywhere on the trigger opens its roster, except on its own
   * buttons, links and forms; the title's button is the keyboard's way in.
   * A click the keyboard sent (`detail` 0) moves the focus into the panel.
   */
  openFromTrigger(event) {
    const opener = event.target.closest("[data-roster-open]");
    const clickInsideAction = event.target.closest(
      ".group-row__actions, .group-row__self-enrollment, "
      + ".tutorial-roster-student-remove, a, button, form",
    );

    if (clickInsideAction && !opener) {
      return;
    }

    if (!opener && window.getSelection()?.toString()) {
      return;
    }

    const trigger = event.currentTarget;
    const panelPath = trigger?.dataset?.rosterPanelPath;
    if (!trigger || !panelPath) {
      return;
    }

    if (this.isOpen && trigger.dataset.rosterKey === this.activeRosterKey) {
      this.close();
      return;
    }

    this.focusPanelOnLoad = event.detail === 0;
    this.activate(trigger);
    this.openPanel();
    this.requestPanel(panelPath);
  }

  rememberFocus(event) {
    this.focusedRosterKey = event.currentTarget.dataset.rosterKey || null;
  }

  /**
   * Puts the focus back on the row's title: a Turbo Stream that replaces the
   * row the keyboard was on leaves it on <body>.
   */
  restoreFocus(trigger) {
    if (!this.focusedRosterKey || trigger.dataset.rosterKey !== this.focusedRosterKey) {
      return;
    }
    if (document.activeElement && document.activeElement !== document.body) {
      return;
    }

    trigger.querySelector("[data-roster-open]")?.focus();
  }

  close() {
    const wasOpen = this.isOpen;
    const trigger = this.activeTrigger;

    this.isOpen = false;
    this.element.classList.remove("tutorial-roster-layout--open");
    this.element.classList.add("tutorial-roster-layout--closed");
    this.lecturePaneElement?.classList.remove("lecture-pane--roster-panel-open");

    if (trigger) {
      this.markSelected(trigger, false);
    }

    this.activeTrigger = null;
    this.activeRosterKey = null;

    if (wasOpen && trigger && this.panelHasFocus()) {
      trigger.querySelector("[data-roster-open]")?.focus();
    }
  }

  closeOnLeavingLanes(event) {
    const fromTarget = event.relatedTarget?.dataset?.bsTarget;
    const toTarget = event.target?.dataset?.bsTarget;

    if (fromTarget !== "#lanes-pane" || toTarget === "#lanes-pane") {
      return;
    }

    this.close();
  }

  panelHasFocus() {
    return this.hasPanelCardTarget && this.panelCardTarget.contains(document.activeElement);
  }

  openPanel() {
    this.isOpen = true;
    this.element.classList.add("tutorial-roster-layout--open");
    this.element.classList.remove("tutorial-roster-layout--closed");
    this.lecturePaneElement?.classList.add("lecture-pane--roster-panel-open");

    if (this.panelIsStacked()) {
      this.panelCardTarget.scrollIntoView({ behavior: "smooth", block: "start" });
    }
  }

  panelIsStacked() {
    if (!this.hasPanelShellTarget) {
      return false;
    }

    const shellStyles = window.getComputedStyle(this.panelShellTarget);
    return shellStyles.position === "static";
  }

  panelCardTargetConnected(panel) {
    if (!this.focusPanelOnLoad) {
      return;
    }

    this.focusPanelOnLoad = false;
    panel.querySelector("[data-roster-panel-heading]")?.focus();
  }

  filter() {
    if (!this.hasListTarget || !this.hasNoResultsTarget) {
      return;
    }

    const query = this.filterInputTarget.value.trim().toLowerCase();
    const rows = this.listTarget.querySelectorAll("[data-student-search]");
    let visibleCount = 0;

    rows.forEach((row) => {
      const haystack = row.dataset.studentSearch || "";
      const visible = query.length === 0 || haystack.includes(query);
      row.classList.toggle("d-none", !visible);
      if (visible) visibleCount += 1;
    });

    const showNoResults = query.length > 0 && visibleCount === 0;
    this.noResultsTarget.classList.toggle("d-none", !showNoResults);
  }

  activate(trigger) {
    if (this.activeTrigger) {
      this.markSelected(this.activeTrigger, false);
    }

    this.activeTrigger = trigger;
    this.activeRosterKey = trigger.dataset.rosterKey || null;
    this.markSelected(trigger, true);
  }

  markSelected(trigger, selected) {
    trigger.classList.toggle(SELECTED, selected);
    trigger.querySelector("[data-roster-open]")
      ?.setAttribute("aria-expanded", String(selected));
  }

  async requestPanel(panelPath) {
    const response = await fetch(panelPath, {
      headers: {
        "accept": "text/vnd.turbo-stream.html",
        "X-Requested-With": "XMLHttpRequest",
      },
      credentials: "same-origin",
    });

    if (!response.ok) {
      return;
    }

    const streamHtml = await response.text();
    Turbo.renderStreamMessage(streamHtml);
  }
}
