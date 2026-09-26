import { Controller } from "@hotwired/stimulus";

/**
 * Points the clicked lecture link to the current page and query, e.g. from
 * /lectures/1/outline to /lectures/3/outline. Done on click, since the sidebar
 * and the edit tabs change the URL without a page load.
 */
export default class extends Controller {
  keepPlace(event) {
    const current = window.location.pathname.match(/^\/lectures\/\d+(\/.*)?$/);
    if (!current) return;

    const page = current[1] || "";
    const link = event.currentTarget;
    const target = new URL(link.href);
    // In edit mode, the link leads to viewing if the user may not edit the
    // other lecture. Then the current page does not apply.
    if ((page === "/edit") !== target.pathname.endsWith("/edit")) return;

    target.pathname = target.pathname.replace(/^(\/lectures\/\d+).*$/, `$1${page}`);
    target.search = window.location.search;
    link.href = target.toString();
  }
}
