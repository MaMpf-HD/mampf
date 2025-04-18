/**
 * Reloads the current page without using the browser cache by using a query
 * parameter that changes on every call (cache busting).
 *
 * Note that images and other assets may still be cached.
 * From https://stackoverflow.com/a/74091027/
 */
// eslint-disable-next-line no-unused-vars
function reloadUrl() {
  console.log("in reloadUrl");
  const queryParams = new URLSearchParams(window.location.search);
  queryParams.set("lr", new Date().getTime());
  const query = queryParams.toString();
  window.location.search = query; // navigates
}
