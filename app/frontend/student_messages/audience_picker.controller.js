import { Controller } from "@hotwired/stimulus";

// "Everybody" or "groups picked": the groups are offered only for the second,
// and a disabled fieldset is not sent along. Every change asks the server how
// many people the selection reaches; the answer is a stream that redraws the
// send button and the addresses to copy.
export default class extends Controller {
  static targets = ["groupsMode", "groups", "sectionToggle", "failure"];
  static values = { url: String };

  connect() {
    this.modeChanged();
  }

  // A reply arriving after a navigation would land on the next page's form.
  disconnect() {
    this.abortController?.abort();
  }

  modeChanged() {
    const picking = this.groupsModeTarget.checked;
    this.groupsTarget.disabled = !picking;
    this.groupsTarget.hidden = !picking;
  }

  // The section's toggle sets every box under it; the boxes set the toggle.
  toggleSection({ target }) {
    for (const box of this.boxesOf(target)) box.checked = target.checked;
    this.changed();
  }

  async changed() {
    // Until the answer is in, the button would send the new selection under
    // the old count.
    for (const control of this.element.querySelectorAll("#student-message-recipients button, #student-message-recipients input[type=submit]")) {
      control.disabled = true;
    }
    this.failureTarget.hidden = true;

    for (const toggle of this.sectionToggleTargets) {
      const boxes = this.boxesOf(toggle);
      const checked = boxes.filter(box => box.checked).length;
      toggle.checked = checked === boxes.length;
      toggle.indeterminate = checked > 0 && checked < boxes.length;
    }

    // A reply still in flight would otherwise overwrite whatever we do next.
    this.abortController?.abort();
    this.abortController = new AbortController();

    const url = new URL(this.urlValue, window.location.href);
    for (const input of this.element.querySelectorAll("input[name$='[audiences][]']:checked")) {
      // `disabled` on the input says nothing about a disabled fieldset around it
      if (!input.matches(":disabled") && input.value) {
        url.searchParams.append("audiences[]", input.value);
      }
    }

    try {
      const response = await fetch(url, {
        headers: { Accept: "text/vnd.turbo-stream.html" },
        signal: this.abortController.signal,
      });
      if (response.ok) {
        window.Turbo.renderStreamMessage(await response.text());
      }
      else {
        this.failureTarget.hidden = false;
      }
    }
    catch (e) {
      if (e.name === "AbortError") return;
      // The controls stay off: the count they show is not the selection's.
      this.failureTarget.hidden = false;
      console.warn("audience-picker: request failed", e);
    }
  }

  boxesOf(toggle) {
    const section = toggle.closest("[data-audience-section]");
    return [...section.querySelectorAll("input[type=checkbox][name]")];
  }
}
