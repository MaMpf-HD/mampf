import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  submit() {
    this.element.requestSubmit();
  }

  debouncedSubmit() {
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      this.element.requestSubmit();
    }, 300);
  }

  disconnect() {
    clearTimeout(this.timeout);
  }
}
