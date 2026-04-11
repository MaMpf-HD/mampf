import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.onLectureSuccess = () => this.show();
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
    document.getElementById("new_lecture")?.replaceChildren();
  }
}
