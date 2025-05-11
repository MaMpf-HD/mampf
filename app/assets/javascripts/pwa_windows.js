/**
 * Opens any link with target="_blank" in a new window when the app is running
 * as a Progressive Web App (PWA).
 *
 * Without this, on Desktop clients, these links would instead open in the
 * default browser, and thus the user would be taken out of the MaMpf app.
 *
 * Notice that on mobile devices, this opening of new windows might not work.
 * Oftentimes, a dummy in-app browser is opened instead, which is also fine.
 *
 * Related:
 * - Original problem: https://stackoverflow.com/q/68993320/
 * - Workaround with new in-app window (what we use here):
 *   https://web.dev/learn/pwa/windows#open_new_windows
 * - Other workaround using "tabbed" mode, but that one is currently experimental:
 *   https://github.com/WICG/manifest-incubations/blob/gh-pages/tabbed-mode-explainer.md
 */
$(document).on("turbolinks:load", function () {
  $(document).on("click", "a[target='_blank']", function (event) {
    const url = $(this).attr("href");
    const isPWA = window.matchMedia("(display-mode: standalone)").matches
      || window.navigator.standalone;

    if (!isPWA || !url) {
      return;
    }

    event.preventDefault();
    const width = window.screen.width / 2;
    const height = window.screen.height / 2;
    window.open(url, "MaMpf Media View", `width=${width},height=${height}`);
  });
});
