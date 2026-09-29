import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";

// A select whose options are pages: choosing one goes there. The options
// carry paths the server wrote, so this is a Turbo visit, not an assignment
// to the location from whatever the option holds.
export default class extends Controller {
  visit() {
    Turbo.visit(this.element.value);
  }
}
