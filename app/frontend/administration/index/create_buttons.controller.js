import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.hide();
  }

  disconnect() {
    this.show();
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
    document.getElementById("new_course")?.replaceChildren();
  }

  submitEnd(event) {
    if (event.detail.success) {
      this.show();
    }
  }
}
