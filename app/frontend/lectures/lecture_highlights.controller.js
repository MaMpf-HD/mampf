import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  highlightMedium(event) {
    const medium = event.currentTarget;
    if (medium.dataset.type === "Lesson") {
      this.highlightLessonById(medium.dataset.id);
    }

    for (const tag of this.idsFrom(medium.dataset.tags)) {
      for (const element of this.tagElements(tag)) {
        element.classList.remove("bg-light");
        element.classList.add("bg-warning");
      }
    }
  }

  resetMedium(event) {
    const medium = event.currentTarget;
    if (medium.dataset.type === "Lesson") {
      this.resetLessonById(medium.dataset.id);
    }

    for (const tag of this.idsFrom(medium.dataset.tags)) {
      for (const element of this.tagElements(tag)) {
        element.classList.remove("bg-warning");
      }
    }
  }

  highlightLesson(event) {
    for (const tag of this.idsFrom(event.currentTarget.dataset.tags)) {
      for (const element of this.tagElements(tag)) {
        element.classList.add("bg-warning");
      }
    }
  }

  resetLesson(event) {
    for (const tag of this.idsFrom(event.currentTarget.dataset.tags)) {
      for (const element of this.tagElements(tag)) {
        element.classList.remove("bg-warning");
      }
    }
  }

  highlightTag(event) {
    for (const lesson of this.idsFrom(event.currentTarget.dataset.lessons)) {
      this.highlightLessonById(lesson);
    }
  }

  resetTag(event) {
    for (const lesson of this.idsFrom(event.currentTarget.dataset.lessons)) {
      this.resetLessonById(lesson);
    }
  }

  highlightLessonById(lesson) {
    for (const element of this.lessonElements(lesson)) {
      element.classList.remove("bg-secondary");
      element.classList.add("bg-info");
    }
  }

  resetLessonById(lesson) {
    for (const element of this.lessonElements(lesson)) {
      element.classList.remove("bg-info");
      element.classList.add("bg-secondary");
    }
  }

  lessonElements(lesson) {
    return this.element.querySelectorAll(`.lecture-lesson[data-id="${CSS.escape(lesson)}"]`);
  }

  tagElements(tag) {
    return this.element.querySelectorAll(`.lecture-tag[data-id="${CSS.escape(tag)}"]`);
  }

  idsFrom(value) {
    return JSON.parse(value || "[]");
  }
}
