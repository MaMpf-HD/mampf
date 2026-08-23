import Masonry from "masonry-layout";

$(document).on("turbo:load", function () {
  initMasonryGridSystem();
});

// A grid inside a hidden tab pane measures zero, and every card lands in the
// same spot. Lay out again once the pane is on screen - and look the element up
// each time, because a Turbo Stream can have replaced it since.
document.addEventListener("shown.bs.tab", function () {
  initMasonryGridSystem();
});

/**
 * Inits the masonry grid system for elements with the class "masonry-grid",
 * or lays out the one that is already initialized.
 */
export function initMasonryGridSystem() {
  const gridElement = document.querySelector(".masonry-grid");
  if (!gridElement) return;

  const existing = Masonry.data(gridElement);
  if (existing) {
    existing.layout();
  }
  else {
    new Masonry(gridElement, { percentPosition: true });
  }
}
