$(document).on("turbolinks:load", function () {
  initMasonryGridSystem();
});

/**
 * Inits the masonry grid system for elements with the class "masonry-grid".
 */
function initMasonryGridSystem() {
  $(".masonry-grid").masonry({
    percentPosition: true,
  });
}
