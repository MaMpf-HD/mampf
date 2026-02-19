import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["select"];

  async selectionChanged({ target } = {}) {
    const select = target || this.selectTarget;
    const urlTemplate = select?.dataset.questionCounterUrl;
    if (!urlTemplate) return;

    if (select.selectedOptions.length === 0) {
      document.getElementById("question_counter")?.replaceChildren();
      return;
    }

    this.abortController?.abort();
    this.abortController = new AbortController();

    const url = new URL(urlTemplate, window.location.href);
    for (const option of select.selectedOptions) {
      url.searchParams.append("tag_ids[]", option.value);
    }

    try {
      const response = await fetch(url, {
        headers: { Accept: "text/vnd.turbo-stream.html" },
        signal: this.abortController.signal,
      });

      if (response.ok) {
        window.Turbo?.renderStreamMessage?.(await response.text());
      }
    }
    catch (e) {
      if (e.name !== "AbortError") console.warn("question-counter: request failed", e);
    }
  }
}
