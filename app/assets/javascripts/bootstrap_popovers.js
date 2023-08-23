$(document).on('turbolinks:load', function () {
    console.log('I am in bootstrap_popovers.js');
    reenableBootstrapPopovers();
});

/**
 * Reinitialize all Bootstrap popovers on the page.
 * This function might be used for the first initialization of popovers as well
 * as for the reinitialization, e.g. after a page change via Turbolinks.
 *
 * See: https://getbootstrap.com/docs/5.3/components/popovers/#enable-popovers
 */
function reenableBootstrapPopovers() {
    const popoverHtmlElements = document.querySelectorAll('[data-bs-toggle="popover"]');
    for (const element of popoverHtmlElements) {
        new bootstrap.Popover(element);
    }
}