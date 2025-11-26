import Masonry from "masonry-layout";

$(document).on("turbo:load", function () {
  initMasonryGridSystem();
});

/**
 * Inits the masonry grid system for elements with the class "masonry-grid".
 */
export function initMasonryGridSystem() {
  const gridElements = document.querySelector(".masonry-grid");
  if (gridElements) {
    new Masonry(gridElements, {
      percentPosition: true,
    });
  }
}
