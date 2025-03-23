/**
 * Takes care of the URL hashes, such that each bootstrab tab gets assigned
 * its own URL hash, e.g. "#assignments".
 *
 * This is necessary to be able to share the URL with a specific tab open.
 * It also allows to stay on the same tab after a page reload
 * (which is done when an edit action is saved/canceled,
 * also see the lectures controller update action).
 *
 * Find out more details in this guide:
 * https://webdesign.tutsplus.com/how-to-add-deep-linking-to-the-bootstrap-4-tabs-component--cms-31180t
 */
function configureUrlHashesForBootstrapTabs() {
  $('#lecture-nav-pills button[role="tab"]').off("focus").on("focus", function () {
    const hash = $(this).attr("href");
    if (hash === "#content") {
      // Do not add a hash for the content tab, as this is the default tab.
      // Otherwise, users cannot navigate back anymore to the previous tab
      // since this is triggered.
      return;
    }
    const urlWithoutHash = location.href.split("#")[0];
    const newUrl = `${urlWithoutHash}${hash}`;
    // https://github.com/turbolinks/turbolinks-classic/issues/363#issuecomment-85626145
    history.pushState({ turbolinks: true, url: newUrl }, "", newUrl);
  });
}

function navigateToActiveNavTab() {
  if (location.hash) {
    const hrefXPathIdentifier = `button[href="${location.hash}"]`;
    $(`#lecture-nav-pills ${hrefXPathIdentifier}`).tab("show");
  }
  else {
    const newUrl = `${location.href.split("#")[0]}#content`;
    history.replaceState({ turbolinks: true, url: newUrl }, "", newUrl);
    $("#lecture-nav-content").focus();
  }
}

$(document).ready(function () {
  initBootstrapPopovers();
  configureUrlHashesForBootstrapTabs();
  navigateToActiveNavTab();

  // Reinitialize the masonry grid system when the lecture content is shown
  $("#lecture-nav-content").on("shown.bs.tab", () => {
    initMasonryGridSystem();
  });
});

$(window).on("hashchange", function () {
  navigateToActiveNavTab();
});
