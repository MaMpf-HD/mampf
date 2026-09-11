import { Controller } from "@hotwired/stimulus";

export const POSITION_KEY_PREFIX = "vignettes.position.";

/**
 * Keeps the slide position in the browser so a vignette can be resumed, and
 * drops it again on the closing page -- that is, once the vignette really is
 * over, rather than when the last button was pressed and the answer might
 * still be rejected.
 */
export default class extends Controller {
  static values = {
    questionnaire: Number,
    position: Number,
    finished: Boolean,
  };

  connect() {
    this.write(this.finishedValue ? null : this.positionValue);
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
