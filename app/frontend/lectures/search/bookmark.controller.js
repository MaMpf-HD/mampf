import { Controller } from "@hotwired/stimulus";

/**
 * The bookmark toggle on a lecture search result: adds or removes the lecture
 * from the student's dashboard bookmarks.
 *
 * The button flips straight away and the request is sent in the background;
 * a failed request puts the button back the way it was, so the shown state
 * always matches what is stored.
 */
export default class extends Controller {
  static targets = ["icon", "button"];
  static values = { url: String, bookmarked: Boolean };

  toggle(event) {
    // the button sits on top of the card's own link
    event.preventDefault();
    event.stopPropagation();

    const method = this.bookmarkedValue ? "DELETE" : "POST";
    this.bookmarkedValue = !this.bookmarkedValue;
    this.render();
    this.save(method);
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
    // absent where forgery protection is off, e.g. the test environment
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;

    const response = await fetch(this.urlValue, {
      method,
      headers: {
        "Accept": "application/json",
        "X-CSRF-Token": csrfToken,
      },
    });

    if (!response.ok) {
      this.bookmarkedValue = !this.bookmarkedValue;
      this.render();
      console.error(`bookmark: the change was not saved (${response.status})`);
    }
  }
}
