import { Controller } from "@hotwired/stimulus";

/**
 * The dashboard's term picker.
 */
export default class extends Controller {
  static targets = ["select"];

  change(event) {
    const { url } = event.target.selectedOptions[0].dataset;
    window.history.replaceState(window.history.state, "", url);

    const { form } = event.target;
    form.addEventListener("turbo:submit-end", () => {
      this.dispatch("changed", { target: document });
    }, { once: true });

    form.requestSubmit();
  }

  /**
   * Switches the picker to the given term, as if picked from the dropdown.
   */
  pick(event) {
    event.preventDefault();
    this.selectTarget.value = event.params.term;
    this.selectTarget.dispatchEvent(new Event("change"));
  }
}
