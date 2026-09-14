import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";

// The dialog belongs to the table, the request to the row that opened it.
// Focus goes back to that row afterwards: to the button that opened the
// dialog, or, once a save has replaced the row, to the new row's first control.
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

  submit() {
    this.focusRowOnArrival();
    this.hide();
  }

  restoreFocus = () => {
    if (this.trigger?.isConnected) {
      this.trigger.focus();
      return;
    }
    this.focusRow();
  };

  // The button lived in the row's last cell; its successor is there too.
  focusRow() {
    const row = document.getElementById(this.rowId);
    const control = row?.querySelector("td:last-child :is(a, button)")
      || row?.querySelector("a, button, select, input");
    control?.focus();
  }

  // The answer streams the row back; focusing after that stream has rendered
  // is the only moment the new row is certainly there.
  focusRowOnArrival() {
    const rowId = this.rowId;
    this.onArrival = (event) => {
      if (event.target.target !== rowId) {
        return;
      }
      this.forgetArrival();
      const render = event.detail.render;
      event.detail.render = (stream) => {
        render(stream);
        this.focusRow();
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
