import { Controller } from "@hotwired/stimulus";

/**
 * The dashboard's semester picker.
 *
 * Changing the `<select>` does a Turbo visit to the chosen semester
 * (`/?term=<id>`, optionally with a `#lecture-search` fragment), which
 * re-renders the dashboard sections and the lecture search for that term.
 * Every copy of the picker on the page is server-rendered from the same
 * selected term, so they stay in sync without any client state.
 *
 * The option values are the target paths themselves, so a plain form GET is
 * still a sensible fallback when JS is unavailable.
 */
export default class extends Controller {
  visit(event) {
    // set globally by @hotwired/turbo-rails in initHotwire
    window.Turbo.visit(event.target.value);
  }
}
