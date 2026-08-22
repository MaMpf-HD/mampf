import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  submitEnd(event) {
    if (event.detail.success) {
      document.dispatchEvent(new CustomEvent("lecture:new:success"));
    }
  }
}
