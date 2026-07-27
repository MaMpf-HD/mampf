import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["changeButton", "requestDataToast"];

  showChangeBanner() {
    for (const button of this.changeButtonTargets) {
      button.classList.remove("d-none");
    }
  }

  updateLectureRegistration(event) {
    const checkbox = event.currentTarget;
    const { course, lecture } = checkbox.dataset;
    const lectureId = parseInt(lecture);

    const checkedCount = this.element.querySelectorAll(
      `input:checked[data-course="${CSS.escape(course)}"]`,
    ).length;
    const authRequiredLectureIds = this.authRequiredLectureIds(course);

    for (const courseInfo of this.element.querySelectorAll(
      `.courseSubInfo[data-course="${CSS.escape(course)}"]`,
    )) {
      courseInfo.classList.toggle("fas", checkedCount > 0);
      courseInfo.classList.toggle("fa-check-circle", checkedCount > 0);
      courseInfo.classList.toggle("far", checkedCount === 0);
      courseInfo.classList.toggle("fa-circle", checkedCount === 0);
    }

    const showPasswordField = checkbox.checked && authRequiredLectureIds.includes(lectureId);
    const passwordField = this.element.querySelector(`#pass-lecture-${lectureId}`);
    if (passwordField) {
      passwordField.style.display = showPasswordField ? "" : "none";
    }
  }

  moveCourseCardsIntoProgram(event) {
    const programCollapse = event.currentTarget;
    for (const placeholder of programCollapse.querySelectorAll(".coursePlaceholder")) {
      const course = placeholder.dataset.course;
      const courseCard = this.element.querySelector(`#course-card-${course}`);
      placeholder.append(courseCard);
      courseCard.style.display = "";
    }
  }

  showRequestDataToast() {
    const toast = this.requestDataToastTarget;
    bootstrap.Toast.getOrCreateInstance(toast).show();
  }

  authRequiredLectureIds(course) {
    const lectures = this.element.querySelector(`#lectures-for-course-${course}`);
    return JSON.parse(lectures.dataset.authorize);
  }
}
