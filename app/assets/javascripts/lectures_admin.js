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
  $('#lecture-nav-pills button[role="tab"]').on("focus", function () {
    const hash = $(this).attr("href");
    const urlWithoutHash = location.href.split("#")[0];
    const newUrl = `${urlWithoutHash}${hash}`;
    history.pushState(null, "", newUrl);
  });
}

function navigateToActiveNavTab() {
  if (location.hash) {
    const hrefXPathIdentifier = `button[href="${location.hash}"]`;
    $(`#lecture-nav-pills ${hrefXPathIdentifier}`).tab("show");
  }
  else {
    $("#lecture-nav-content").focus();
  }
}

$(document).on("ready turbolinks:load", function () {
  initBootstrapPopovers();
  configureUrlHashesForBootstrapTabs();
  navigateToActiveNavTab();

  // Reinitialize the masonry grid system when the lecture content is shown
  $("#lecture-nav-content").on("click", () => {
    initMasonryGridSystem();
  });
});

$(window).on("hashchange", function () {
  navigateToActiveNavTab();
});
