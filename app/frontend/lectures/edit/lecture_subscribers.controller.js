import { Controller } from "@hotwired/stimulus";

// Fills the subscriber modal on first sight. connect() rather than a page
// event, so it also runs when this arrives with a Turbo visit or a stream.
export default class extends Controller {
  static targets = ["list", "button"];
  static values = { lecture: Number, loaded: Boolean };

  connect() {
    if (this.loadedValue || this.fetching || !this.hasListTarget) return;

    this.fetching = true;
    fetch(Routes.show_subscribers_path(this.lectureValue, { lecture: this.lectureValue }),
      { headers: { Accept: "application/json" } })
      .then(response => response.json())
      .then((subscribers) => {
        this.render(subscribers);
        // Only now: a page cached while this was in flight would otherwise come
        // back with an empty list that believes it is filled.
        this.loadedValue = true;
      })
      .finally(() => { this.fetching = false; });
  }

  render(subscribers) {
    if (subscribers.length === 0 && this.hasButtonTarget) {
      this.buttonTarget.style.display = "none";
      return;
    }

    for (const [name, mail] of subscribers) {
      const row = document.createElement("div");
      row.className = "row mx-2 border-left border-right border-bottom";
      row.appendChild(this.column(name));
      row.appendChild(this.column(mail));
      this.listTarget.appendChild(row);
    }
  }

  column(content) {
    const column = document.createElement("div");
    column.className = "col-6";
    column.textContent = content;
    return column;
  }
}
