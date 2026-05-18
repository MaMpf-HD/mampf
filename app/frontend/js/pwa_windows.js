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
$(document).on("turbo:load", function () {
  $(document).on("click", "a[target='_blank'], a[target='blank']", function (event) {
    const url = $(this).attr("href");
    const isPWA = window.matchMedia("(display-mode: standalone)").matches
      || window.navigator.standalone;

    if (!isPWA || !url) {
      return;
    }

    event.preventDefault();

    // Most MaMpf videos are 2:3 and (unfortunately) don't have any remarks
    // in the right sidebar, which would make the format 16:9. So, by default,
    // we open the new window in 2:3 format. The user can always resize it later
    // to their likings. Note that this window does not only host videos, but
    // also other media, such as PDFs.
    const width = 0.5 * window.screen.width;
    const height = (2 / 3) * width;
    window.open(url, "MaMpf Media View", `width=${width},height=${height},left=50,top=50`);
  });
});
