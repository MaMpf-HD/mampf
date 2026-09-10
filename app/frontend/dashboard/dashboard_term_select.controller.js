import { Controller } from "@hotwired/stimulus";

/**
 * The dashboard's semester picker.
 *
 * Changing the `<select>` refreshes only the term-dependent parts of the page
 * in place — the dashboard sections, every copy of the picker, and the hidden
 * field the lecture search reads its term from — through a Turbo Stream
 * response (`main/start.turbo_stream.erb`). No full navigation happens, so the
 * scroll position is kept. The URL is still updated to `/?term=<id>` so the
 * choice survives a reload or a shared link.
 *
 * The lecture search below listens for the `dashboard-term-select:changed`
 * event and re-runs itself once the hidden term field has been swapped.
 */
export default class extends Controller {
  change(event) {
    const url = event.target.value;

    window.history.replaceState(window.history.state, "", url);

    fetch(url, {
      headers: { Accept: "text/vnd.turbo-stream.html" },
      credentials: "same-origin",
    })
      .then(response => response.text())
      .then((html) => {
        // set globally by @hotwired/turbo-rails in initHotwire
        window.Turbo.renderStreamMessage(html);
        this.dispatch("changed", { target: document });
      });
  }
}
