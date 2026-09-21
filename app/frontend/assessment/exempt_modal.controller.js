import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";

// Manages the exam exemption dialog and restores focus to its row.
export default class extends Controller {
  static targets = ["form", "note"];

  connect() {
    this.modal = new Modal(this.element);
    this.element.addEventListener("hidden.bs.modal", this.restoreFocus);
  }

  disconnect() {
    this.element.removeEventListener("hidden.bs.modal", this.restoreFocus);
    this.forgetArrival();
    this.modal.dispose();
  }

  open({ detail: { url, note, trigger } }) {
    this.forgetArrival();
    this.trigger = trigger;
    this.rowId = trigger?.closest("tr")?.id;
    this.formTarget.action = url;
    this.noteTarget.value = note || "";
    this.modal.show();
  }

  hide() {
    this.modal.hide();
  }

  // The arrival listener belongs to this one request: a refusal answers
  // with a flash and no row, and must not leave it waiting for a later one.
  submit() {
    this.focusRowOnArrival();
    this.formTarget.addEventListener("turbo:submit-end", () => this.forgetArrival(),
      { once: true });
    this.hide();
  }

  restoreFocus = () => {
    if (this.trigger?.isConnected) {
      this.trigger.focus();
      return;
    }
    this.focusRow();
  };

  // A row the filter has just hidden cannot take focus; the nearest row
  // still shown takes it, or the name filter when none is.
  focusRow() {
    const row = document.getElementById(this.rowId);
    if (!row) {
      return;
    }
    const target = row.hidden ? this.neighbourOf(row) : row;
    const control = target ? this.controlIn(target) : this.filterOf(row);
    control?.focus();
  }

  // Prefer the action cell so an exemption returns focus to its undo link.
  controlIn(row) {
    return row.querySelector("td:last-child :is(a, button)")
      || row.querySelector("a, button, select, input");
  }

  neighbourOf(row) {
    let next = row.nextElementSibling;
    while (next?.hidden) {
      next = next.nextElementSibling;
    }
    let previous = row.previousElementSibling;
    while (previous?.hidden) {
      previous = previous.previousElementSibling;
    }
    return next || previous;
  }

  filterOf(row) {
    return row.closest("[data-controller~=status-filter]")
      ?.querySelector("[data-status-filter-target=name]");
  }

  // Wait for the row replacement before focusing a control in the new row.
  focusRowOnArrival() {
    const rowId = this.rowId;
    this.onArrival = (event) => {
      if (event.target.target !== rowId) {
        return;
      }
      this.forgetArrival();
      const render = event.detail.render;
      // The filter hides or shows the new row in a microtask of its own;
      // focus goes after that has run.
      event.detail.render = (stream) => {
        render(stream);
        queueMicrotask(() => this.focusRow());
      };
    };
    document.addEventListener("turbo:before-stream-render", this.onArrival);
  }

  forgetArrival() {
    if (this.onArrival) {
      document.removeEventListener("turbo:before-stream-render", this.onArrival);
      this.onArrival = null;
    }
  }
}
