$(document).on('turbolinks:load', function () {
    initBootstrapPopovers();
});

/**
 * Initializes all Bootstrap popovers on the page.
 * 
 * This function might be used for the first initialization of popovers as well
 * as for reinitialization on page changes.
 *
 * See: https://getbootstrap.com/docs/5.3/components/popovers/#enable-popovers
 */
function initBootstrapPopovers() {
    const popoverHtmlElements = document.querySelectorAll('[data-bs-toggle="popover"]');
    for (const element of popoverHtmlElements) {
        new bootstrap.Popover(element);
    }
}