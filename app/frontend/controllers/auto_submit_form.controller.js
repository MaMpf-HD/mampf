import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["searchInput", "clearButton"];

  connect() {
    if (!this.hasSearchInputTarget) return;

    this.toggleClearButton();

    if (this.searchInputTarget.value.length > 0) {
      const input = this.searchInputTarget;
      input.focus();
      input.setSelectionRange(input.value.length, input.value.length);
    }
  }

  submit() {
    this.element.requestSubmit();
  }

  debouncedSubmit() {
    clearTimeout(this.timeout);
    this.toggleClearButton();
    this.timeout = setTimeout(() => {
      this.element.requestSubmit();
    }, 300);
  }

  clear() {
    if (!this.hasSearchInputTarget) return;

    this.searchInputTarget.value = "";
    this.toggleClearButton();
    this.element.requestSubmit();
  }

  toggleClearButton() {
    if (!this.hasClearButtonTarget || !this.hasSearchInputTarget) return;

    const hasValue = this.searchInputTarget.value.length > 0;
    this.clearButtonTarget.classList.toggle("d-none", !hasValue);
    this.searchInputTarget.classList.toggle("border-end-0", hasValue);
    this.searchInputTarget.classList.toggle("rounded-end", !hasValue);
  }

  disconnect() {
    clearTimeout(this.timeout);
  }
}
