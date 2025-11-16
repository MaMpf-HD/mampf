import Sortable from "sortablejs";

$(document).on("turbo:load", function () {
  const $slideList = $("#slides");
  const editable = $slideList.data("questionnaire-editable");
  if (editable) {
    createSortableVignetteSlides($slideList);
  }
});

/**
 * Makes the Vignettes slides draggable, such that users can drag them around
 * to change their order.
 */
function createSortableVignetteSlides(slideList) {
  Sortable.create(slideList.get(0), {
    animation: 150,
    filter: ".accordion-collapse",
    preventOnFilter: false,
    onEnd: function (evt) {
      if (evt.oldIndex == evt.newIndex) return;

      const questionnaire_id = evt.target.dataset.questionnaireId;
      $.ajax({
        url: `/questionnaires/${questionnaire_id}/update_slide_position`,
        method: "PATCH",
        data: {
          old_position: evt.oldIndex,
          new_position: evt.newIndex,
        },
        error: function (xhr, status, error) {
          console.error(`Failed to update position: ${error}`);
        },
      });
    },
  });
}
