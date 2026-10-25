import { Controller } from "@hotwired/stimulus";

const DEFAULT_DELAY = 300;

// A frame swap takes the field somebody is typing in with it: the node that
// holds the caret is removed, and every keystroke after that lands nowhere.
// What was typed is handed from the field that goes to the one that arrives,
// keyed by the form it belongs to so that two searches on one page cannot
// take each other's.
const carriedTyping = new Map();

export default class extends Controller {
  static targets = ["form", "searchInput", "clearButton", "filterInput"];
  static values = { delay: Number };

  submit(event) {
    const form = event.target.form || this.element;
    form?.requestSubmit();
  }

  connect() {
    if (!this.hasFormTarget || !this.hasSearchInputTarget) return;

    this.submitStartHandler = this.submitStarted.bind(this);
    this.submitEndHandler = this.submitFinished.bind(this);
    this.beforeRenderHandler = this.carryTyping.bind(this);

    this.formTarget.addEventListener("turbo:submit-start", this.submitStartHandler);
    this.formTarget.addEventListener("turbo:submit-end", this.submitEndHandler);
    document.addEventListener("turbo:before-frame-render", this.beforeRenderHandler);

    this.submitting = false;
    this.lastSubmittedValue = this.searchInputTarget.value;
    this.toggleClearButton();
    this.resumeTyping();
  }

  // Asked before the frame is taken apart, because that is the last moment at
  // which the field is still in the page and can be asked whether it has the
  // caret - a browser blurs it on the way out, so afterwards nobody can tell.
  carryTyping(event) {
    if (!this.hasFormTarget || !this.hasSearchInputTarget) return;
    if (!event.target.contains(this.element)) return;
    if (document.activeElement !== this.searchInputTarget) return;

    carriedTyping.set(this.typingKey, {
      value: this.searchInputTarget.value,
      caret: this.searchInputTarget.selectionStart,
    });
  }

  resumeTyping() {
    const typed = carriedTyping.get(this.typingKey);
    if (!typed) return;

    carriedTyping.delete(this.typingKey);

    if (typed.value !== this.searchInputTarget.value) {
      this.searchInputTarget.value = typed.value;
      // what arrived after the request went out has not been asked for yet
      this.debouncedSubmit();
    }

    this.searchInputTarget.focus({ preventScroll: true });
    this.searchInputTarget.setSelectionRange(typed.caret, typed.caret);
  }

  get typingKey() {
    return `${this.formTarget.action}#${this.searchInputTarget.name}`;
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

    if (this.beforeRenderHandler) {
      document.removeEventListener("turbo:before-frame-render", this.beforeRenderHandler);
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
