import { Controller } from "@hotwired/stimulus";

const DEFAULT_DELAY = 300;

export default class extends Controller {
  static targets = ["form", "searchInput", "clearButton", "filterInput"];
  static values = { delay: Number };

  connect() {
    if (!this.hasFormTarget || !this.hasSearchInputTarget) return;

    this.submitStartHandler = this.submitStarted.bind(this);
    this.submitEndHandler = this.submitFinished.bind(this);

    this.formTarget.addEventListener("turbo:submit-start", this.submitStartHandler);
    this.formTarget.addEventListener("turbo:submit-end", this.submitEndHandler);

    this.submitting = false;
    this.lastSubmittedValue = this.searchInputTarget.value;
    this.toggleClearButton();
  }

  debouncedSubmit() {
    if (!this.hasFormTarget || !this.hasSearchInputTarget) return;

    clearTimeout(this.timeout);
    this.toggleClearButton();

    this.timeout = setTimeout(() => {
      this.submitIfNeeded();
    }, this.delay);
  }

  clear(event) {
    event.preventDefault();
    if (!this.hasSearchInputTarget) return;

    this.searchInputTarget.value = "";
    this.toggleClearButton();
    this.searchInputTarget.focus({ preventScroll: true });
    this.submitIfNeeded();
  }

  keepFocus(event) {
    event.preventDefault();
  }

  toggleClearButton() {
    if (!this.hasClearButtonTarget || !this.hasSearchInputTarget) return;

    const hasValue = this.searchInputTarget.value.length > 0;
    this.clearButtonTarget.classList.toggle("d-none", !hasValue);
  }

  disconnect() {
    clearTimeout(this.timeout);

    if (this.hasFormTarget && this.submitStartHandler) {
      this.formTarget.removeEventListener("turbo:submit-start", this.submitStartHandler);
    }

    if (this.hasFormTarget && this.submitEndHandler) {
      this.formTarget.removeEventListener("turbo:submit-end", this.submitEndHandler);
    }
  }

  submitStarted() {
    this.submitting = true;
  }

  submitFinished() {
    this.submitting = false;

    if (this.needsSubmit()) {
      this.submitIfNeeded();
    }
  }

  submitIfNeeded() {
    if (!this.hasFormTarget || !this.hasSearchInputTarget) return;
    if (this.submitting) return;

    const value = this.searchInputTarget.value;
    if (value === this.lastSubmittedValue) return;

    this.lastSubmittedValue = value;
    this.formTarget.requestSubmit();
  }

  needsSubmit() {
    return this.hasSearchInputTarget
      && this.searchInputTarget.value !== this.lastSubmittedValue;
  }

  filterSelected(event) {
    if (!this.hasFilterInputTarget) return;

    const { filterValue } = event.currentTarget.dataset;
    if (!filterValue) return;

    this.filterInputTarget.value = filterValue;
  }

  get delay() {
    return this.hasDelayValue ? this.delayValue : DEFAULT_DELAY;
  }
}
