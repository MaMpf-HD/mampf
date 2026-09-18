import { Controller } from "@hotwired/stimulus";

// Asks the server how many people the picked groups reach, after every
// change; the answer is a stream that redraws the send button and the
// addresses to copy.
export default class extends Controller {
  static values = { url: String };

  async changed() {
    // A reply still in flight would otherwise overwrite whatever we do next.
    this.abortController?.abort();
    this.abortController = new AbortController();

    const url = new URL(this.urlValue, window.location.href);
    for (const box of this.element.querySelectorAll("input[type=checkbox]:checked")) {
      url.searchParams.append("audiences[]", box.value);
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
      if (e.name !== "AbortError") console.warn("audience-picker: request failed", e);
    }
  }
}
