import { initMasonryGridSystem } from "~/js/masonry_grid";

$(() => {
  initBootstrapPopovers();

  $("#lecture-nav-content").on("shown.bs.tab", () => {
    initMasonryGridSystem();
  });
});
