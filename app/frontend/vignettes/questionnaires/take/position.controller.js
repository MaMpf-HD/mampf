import { Controller } from "@hotwired/stimulus";

export const POSITION_KEY_PREFIX = "vignettes.position.";

/**
 * Keeps the slide position in the browser so a vignette can be resumed.
 * Nothing else is kept, and it is dropped as soon as the vignette is done.
 */
export default class extends Controller {
  static values = {
    questionnaire: Number,
    position: Number,
    last: Boolean,
  };

  connect() {
    this.write(this.positionValue);
  }

  advance() {
    if (this.lastValue) {
      this.write(null);
    }
  }

  // A private window throws on any access, and the vignette has to work there
  // too, only without being resumable.
  write(position) {
    const key = POSITION_KEY_PREFIX + this.questionnaireValue;
    try {
      if (position === null) {
        window.localStorage.removeItem(key);
      }
      else {
        window.localStorage.setItem(key, String(position));
      }
    }
    catch {
      // no resuming here
    }
  }
}
