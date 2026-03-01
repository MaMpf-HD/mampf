import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";
import * as Turbo from "@hotwired/turbo";

export default class extends Controller {
  static values = {
    url: String,
    selector: String,
    frameId: String,
  };

  async open(event) {
    event.preventDefault();

    const modalEl = document.querySelector(this.selectorValue);
    if (!modalEl) return;

    const modal = Modal.getOrCreateInstance(modalEl);
    modal.show();

    const response = await fetch(this.urlValue, {
      headers: {
        "Accept": "text/vnd.turbo-stream.html, text/html, application/xhtml+xml",
        "Turbo-Frame": this.frameIdValue,
      },
    });

    if (response.ok) {
      const html = await response.text();
      Turbo.renderStreamMessage(html);
    }
  }
}
