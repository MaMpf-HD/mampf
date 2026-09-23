import { Controller } from "@hotwired/stimulus";

// The proxy refuses a body above the upload limit before the app can answer,
// so the size is checked here: the browser does not submit a field that
// reports itself invalid.
export default class extends Controller {
  static values = { max: Number, message: String };

  check() {
    const file = this.element.files[0];
    const tooLarge = file && file.size > this.maxValue;
    this.element.setCustomValidity(tooLarge ? this.messageValue : "");
    this.element.reportValidity();
  }
}
