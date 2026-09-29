import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["course", "term", "termField", "sortField"];

  connect() {
    this.courseChanged();
  }

  /**
   * A term-independent course takes neither a term nor a type, so both fields
   * are hidden and the term is disabled, which keeps it out of the request.
   */
  courseChanged() {
    if (!this.hasCourseTarget) return;

    const courseId = parseInt(this.courseTarget.value);
    const info = JSON.parse(this.courseTarget.dataset.terminfo)
      .find(([id]) => id === courseId);
    if (!info) return;

    const termIndependent = info[1];
    this.termTarget.classList.remove("is-invalid");
    this.termTarget.disabled = termIndependent;
    this.termFieldTarget.style.display = termIndependent ? "none" : "";
    this.sortFieldTarget.style.display = termIndependent ? "none" : "";
  }

  submitEnd(event) {
    if (event.detail.success) {
      document.dispatchEvent(new CustomEvent("lecture:new:success"));
    }
  }
}
