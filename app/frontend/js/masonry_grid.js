import Masonry from "masonry-layout";

let grid = null;

$(document).on("turbo:load", function () {
  initMasonryGridSystem();
});

// A grid inside a hidden tab pane measures zero, and every card lands in the
// same spot. Lay out again once the pane is on screen.
document.addEventListener("shown.bs.tab", function () {
  grid?.layout();
});

/**
 * Inits the masonry grid system for elements with the class "masonry-grid".
 */
export function initMasonryGridSystem() {
  const gridElement = document.querySelector(".masonry-grid");
  grid = gridElement
    ? new Masonry(gridElement, {
        percentPosition: true,
      })
    : null;
}
