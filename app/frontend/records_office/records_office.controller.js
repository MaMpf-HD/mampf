import { Controller } from "@hotwired/stimulus";

/**
 * Filters the term's lectures by what is typed and opens their groups, one
 * lecture or all of them at once.
 */
export default class extends Controller {
  static targets = ["filter", "lecture", "toggle", "none"];

  filter() {
    const words = this.filterTarget.value.toLowerCase().split(/\s+/).filter(Boolean);
    let shown = 0;
    this.lectureTargets.forEach((lecture) => {
      const text = lecture.dataset.filterText;
      const match = words.every(word => text.includes(word));
      lecture.hidden = !match;
      if (match) shown += 1;
    });
    this.noneTarget.hidden = shown > 0;
  }

  toggle(event) {
    const button = event.currentTarget;
    this.setOpen(button, button.getAttribute("aria-expanded") !== "true");
  }

  openAll() {
    this.toggleTargets.forEach(button => this.setOpen(button, true));
  }

  closeAll() {
    this.toggleTargets.forEach(button => this.setOpen(button, false));
  }

  setOpen(button, open) {
    button.setAttribute("aria-expanded", open);
    document.getElementById(button.getAttribute("aria-controls")).hidden = !open;
  }
}
