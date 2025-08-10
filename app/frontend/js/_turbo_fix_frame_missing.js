/**
 * Fixes the "content missing" issue when breaking out of a frame.
 *
 * See the discussions here: https://github.com/hotwired/turbo/issues/257
 * This workaround is provided in this comment:
 * https://github.com/hotwired/turbo/issues/257#issuecomment-1591737862
 */
document.addEventListener("turbo:frame-missing", function (event) {
  event.preventDefault();
  event.detail.visit(event.detail.response);
});
