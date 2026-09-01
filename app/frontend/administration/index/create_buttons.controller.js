import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.onLectureSuccess = () => {
      this.show();
      this.resetFrames();
    };
    document.addEventListener("lecture:new:success", this.onLectureSuccess);
  }

  disconnect() {
    document.removeEventListener("lecture:new:success", this.onLectureSuccess);
  }

  hide() {
    document.getElementById("new-lecture-button")?.classList.add("d-none");
    document.getElementById("new-course-button")?.classList.add("d-none");
  }

  show() {
    document.getElementById("new-lecture-button")?.classList.remove("d-none");
    document.getElementById("new-course-button")?.classList.remove("d-none");
  }

  cancel(event) {
    event.preventDefault();
    this.show();
    this.resetFrames();
  }

  submitEnd(event) {
    if (!event.detail.success) return;

    this.show();
    this.resetFrames();
  }

  /**
   * Empties both creation frames. Dropping the src matters as much as the
   * children: Turbo caches the page on the way out and refetches any frame
   * that still points somewhere, so the form would be back after a click on
   * the browser's back button.
   */
  resetFrames() {
    ["new_lecture", "new_course"].forEach((id) => {
      const frame = document.getElementById(id);
      frame?.removeAttribute("src");
      frame?.replaceChildren();
    });
  }
}
