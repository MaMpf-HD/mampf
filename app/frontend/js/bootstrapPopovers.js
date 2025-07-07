import { Popover } from "bootstrap";

/**
 * Initializes all Bootstrap popovers on the page.
 *
 * This function might be used for the first initialization of popovers as well
 * as for reinitialization on page changes.
 *
 * We need to set this on the window globally, since this function is also needed
 * in .js.erb files rendered directly by Rails and therefore not passing
 * through the Vite build process.
 *
 * See: https://getbootstrap.com/docs/5.3/components/popovers/#enable-popovers
 */
window.initBootstrapPopovers = function () {
  const popoverHtmlElements = document.querySelectorAll('[data-bs-toggle="popover"]');
  for (const element of popoverHtmlElements) {
    new Popover(element);
  }
};
