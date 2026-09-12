import { Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";

/**
 * Makes the vignette's slides draggable so their order can be changed. Bound to
 * the element rather than to a page load, because the editor is also reached
 * through a Turbo frame, where `turbo:load` never fires.
 */
export default class extends Controller {
  static values = { questionnaire: Number, editable: Boolean };

  connect() {
    if (!this.editableValue) return;

    this.sortable = Sortable.create(this.element, {
      animation: 150,
      filter: ".accordion-collapse",
      preventOnFilter: false,
      onEnd: event => this.move(event),
    });
  }

  disconnect() {
    this.sortable?.destroy();
    this.sortable = null;
  }

  move(event) {
    if (event.oldIndex === event.newIndex) return;

    $.ajax({
      url: `/questionnaires/${this.questionnaireValue}/update_slide_position`,
      method: "PATCH",
      data: {
        old_position: event.oldIndex,
        new_position: event.newIndex,
      },
      error: (xhr, status, error) => {
        console.error(`Failed to update position: ${error}`);
      },
    });
  }
}
