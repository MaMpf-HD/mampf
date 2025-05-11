// Add global logic for handling anchor tags with target="_blank" using jQuery and event delegation
// https://stackoverflow.com/q/68993320/
// https://web.dev/learn/pwa/windows#open_new_windows
// https://github.com/WICG/manifest-incubations/blob/gh-pages/tabbed-mode-explainer.md
document.addEventListener("turbolinks:load", function () {
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
    window.open(url, "MaMpf external", `width=${width},height=${height}`);
  });
});
