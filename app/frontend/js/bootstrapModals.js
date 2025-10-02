/**
 * Fixes the following Browser warning due to Bootstrap modals retaining focus
 * after being closed:
 *
 * > Blocked aria-hidden on an element because its descendant retained focus.
 * > The focus must not be hidden from assistive technology users.
 *
 * From https://stackoverflow.com/a/79234586/
 */
function fixBootstrapModalFocusIssue() {
  document.addEventListener("hide.bs.modal", () => {
    if (document.activeElement) {
      document.activeElement.blur();
    }
  });
}

fixBootstrapModalFocusIssue();
