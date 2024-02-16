$(document).on("turbolinks:load", function () {
  $("#search_all_tags").change(evt => toggleSearchAllTags(evt));
});

/**
 * Dynamically enable/disable the OR/AND buttons in the media search form.
 * If the user has decided to search for media regardless of the tags,
 * i.e. they enable the "all" (tags) button, we disable the "OR/AND" buttons
 * as it is pointless to search for media that references *all* available tags
 * at once.
 */
function toggleSearchAllTags(evt) {
  const searchAllTags = evt.target.checked;
  if (searchAllTags) {
    $("#search_tag_operator_or").prop("checked", true);
  }
  $("#search_tag_operator_or").prop("disabled", searchAllTags);
  $("#search_tag_operator_and").prop("disabled", searchAllTags);
}
