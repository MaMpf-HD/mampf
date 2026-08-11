import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.onLectureSuccess = () => {
      this.show();
      this.resetFrame();
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
    this.resetFrame();
  }

  /**
   * Empties the lecture frame. Dropping the src matters as much as the
   * children: Turbo caches the page on the way out and refetches any frame
   * that still points somewhere, so the form would be back after a click on
   * the browser's back button.
   */
  resetFrame() {
    const frame = document.getElementById("new_lecture");
    frame?.removeAttribute("src");
    frame?.replaceChildren();
  }
}
