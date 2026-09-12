import { Controller } from "@hotwired/stimulus";

/**
 * The dashboard's term picker.
 */
export default class extends Controller {
  change(event) {
    const { url } = event.target.selectedOptions[0].dataset;
    window.history.replaceState(window.history.state, "", url);

    document.addEventListener("turbo:submit-end", () => {
      this.dispatch("changed", { target: document });
    }, { once: true });

    event.target.form.requestSubmit();
  }
}
