import { Controller } from "@hotwired/stimulus";
import { sendDashboardRequest } from "~/dashboard/dashboard_request";

/**
 * The bookmark toggle on a lecture search result: adds or removes the lecture
 * from the student's dashboard bookmarks.
 *
 * The button flips straight away; the request comes back as a Turbo Stream
 * that refreshes the "Bookmarked" band above the search, so a bookmarked
 * lecture shows up there at once. A failed request puts the button back.
 *
 * A `bookmark:changed` event keeps this button in sync when the same lecture
 * is unbookmarked elsewhere (the "x" on its card in the band above).
 */
export default class extends Controller {
  static targets = ["icon", "button"];
  static values = { url: String, bookmarked: Boolean, lectureId: Number };

  connect() {
    this.onExternalChange = this.onExternalChange.bind(this);
    window.addEventListener("bookmark:changed", this.onExternalChange);
  }

  disconnect() {
    window.removeEventListener("bookmark:changed", this.onExternalChange);
  }

  toggle(event) {
    // the button sits on top of the card's own link
    event.preventDefault();
    event.stopPropagation();

    const method = this.bookmarkedValue ? "DELETE" : "POST";
    this.bookmarkedValue = !this.bookmarkedValue;
    this.render();
    this.save(method);
  }

  onExternalChange(event) {
    const { lectureId, bookmarked } = event.detail;
    if (lectureId !== this.lectureIdValue) return;
    if (bookmarked === this.bookmarkedValue) return;

    this.bookmarkedValue = bookmarked;
    this.render();
  }

  render() {
    this.element.classList.toggle("is-bookmarked", this.bookmarkedValue);
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-pressed",
        String(this.bookmarkedValue));
    }
    if (this.hasIconTarget) {
      this.iconTarget.classList.toggle("fas", this.bookmarkedValue);
      this.iconTarget.classList.toggle("far", !this.bookmarkedValue);
    }
  }

  async save(method) {
    const response = await sendDashboardRequest(this.urlValue, method);

    if (!response.ok) {
      this.bookmarkedValue = !this.bookmarkedValue;
      this.render();
      console.error(`bookmark: the change was not saved (${response.status})`);
      return;
    }

    // set globally by @hotwired/turbo-rails in initHotwire
    window.Turbo.renderStreamMessage(await response.text());
    window.dispatchEvent(new CustomEvent("bookmark:changed", {
      detail: {
        lectureId: this.lectureIdValue,
        bookmarked: this.bookmarkedValue,
      },
    }));
  }
}
