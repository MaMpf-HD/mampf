import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";

// A path within the app starts with a single slash. What follows is neither
// a second slash nor a backslash, which would name another host, nor a tab
// or a line break, which browsers skip when they read an address.
const APP_PATH = /^\/(?![/\\\t\n\r])/;

// A select whose options are pages: choosing one goes there. Only a path
// within the app is visited. Every other value does nothing, like the empty
// one of the option that stands for the page already shown.
export default class extends Controller {
  visit() {
    const path = this.element.value;
    if (!APP_PATH.test(path)) return;

    Turbo.visit(path);
  }
}
