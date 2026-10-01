import { Controller } from "@hotwired/stimulus";

/**
 * Filters courses by title, teaching-team names and addresses, so the dean's
 * office finds a course within a term.
 */
export default class extends Controller {
  static targets = ["filter", "section", "table", "phase", "course", "unregistered", "none"];

  filter() {
    const words = this.filterTarget.value.toLowerCase().split(/\s+/).filter(Boolean);
    let shown = 0;
    this.courseTargets.forEach((course) => {
      const text = course.dataset.filterText;
      const match = words.every(word => text.includes(word));
      course.hidden = !match;
      if (match) shown += 1;
    });
    this.phaseTargets.forEach((phase) => {
      phase.hidden = !this.visibleCourses(phase.closest("table"))
        .some(course => course.dataset.phase === phase.dataset.phase);
    });
    this.tableTargets.forEach((table) => {
      table.hidden = this.visibleCourses(table).length === 0;
    });
    this.unregisteredTargets.forEach((list) => {
      const any = this.visibleCourses(list).length > 0;
      list.hidden = !any;
      list.open = any && words.length > 0;
    });
    this.sectionTargets.forEach((section) => {
      section.hidden = this.visibleCourses(section).length === 0;
    });
    this.noneTarget.hidden = shown > 0;
  }

  visibleCourses(scope) {
    return this.courseTargets.filter(course => !course.hidden && scope.contains(course));
  }

  toggle(event) {
    const button = event.currentTarget;
    const open = button.getAttribute("aria-expanded") !== "true";
    button.setAttribute("aria-expanded", open);
    document.getElementById(button.getAttribute("aria-controls")).hidden = !open;
  }
}
