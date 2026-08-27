import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["select", "counter"];
  static values = { url: String };

  async selectionChanged() {
    // A reply still in flight would otherwise overwrite whatever we do next.
    this.abortController?.abort();

    if (this.selectTarget.selectedOptions.length === 0) {
      this.counterTarget.replaceChildren();
      return;
    }

    this.abortController = new AbortController();

    const url = new URL(this.urlValue, window.location.href);
    for (const option of this.selectTarget.selectedOptions) {
      url.searchParams.append("tag_ids[]", option.value);
    }

    try {
      const response = await fetch(url, {
        headers: { Accept: "text/vnd.turbo-stream.html" },
        signal: this.abortController.signal,
      });

      if (response.ok) {
        window.Turbo.renderStreamMessage(await response.text());
      }
    }
    catch (e) {
      if (e.name !== "AbortError") console.warn("question-counter: request failed", e);
    }
  }
}
