import { Controller } from "@hotwired/stimulus";
import { POSITION_KEY_PREFIX } from "~/vignettes/questionnaires/take/position.controller.js";

/**
 * Points the overview's links at the slide the reader stopped at, if the
 * browser still remembers one.
 */
export default class extends Controller {
  static targets = ["link"];

  connect() {
    this.linkTargets.forEach(link => this.resume(link));
  }

  resume(link) {
    const position = this.storedPosition(link.dataset.questionnaireId);
    if (position === null || position <= 1) return;

    const url = new URL(link.href, window.location.origin);
    url.searchParams.set("position", String(position));
    link.href = url.toString();

    const label = link.querySelector("[data-resume-label]");
    if (label) label.textContent = label.dataset.resumeLabel;
  }

  storedPosition(questionnaireId) {
    try {
      const stored = window.localStorage.getItem(POSITION_KEY_PREFIX + questionnaireId);
      const position = Number.parseInt(stored, 10);
      return Number.isNaN(position) ? null : position;
    }
    catch {
      return null;
    }
  }
}
