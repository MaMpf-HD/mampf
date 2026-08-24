import { Controller } from "@hotwired/stimulus";

/**
 * Submits the surrounding form as soon as a control changes, for inputs that
 * act on their own — a checkbox that takes effect without a save button.
 */
export default class extends Controller {
  change() {
    this.element.requestSubmit();
  }
}
