/**
 * Reloads the current page without using the browser cache by using a query
 * parameter that changes on every call (cache busting).
 *
 * Note that images and other assets may still be cached.
 * From https://stackoverflow.com/a/74091027/
 *
 * We need to attach this function to the global `window` object so that it can
 * be called from JS / JS-ERB files sent from the server (in controllers).
 */
window.reloadUrl = function () {
  console.log("Reloading URL with cache busting...");
  const queryParams = new URLSearchParams(window.location.search);
  queryParams.set("lr", new Date().getTime());
  const query = queryParams.toString();
  window.location.search = query; // navigates
};
