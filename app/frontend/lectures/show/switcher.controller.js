import { Controller } from "@hotwired/stimulus";

/**
 * Keeps the place in the lecture when switching to another one: the same page
 * of the other lecture, e.g. /lectures/3/lesson_materials when on
 * /lectures/1/lesson_materials, along with the query (e.g. the edit page's
 * tab). Pages the other lecture has nothing on send to its home page by
 * themselves. The place lives only on the client (the sidebar and the tabs
 * update the URL), hence it is added to the link just when it is clicked.
 */
export default class extends Controller {
  keepPlace(event) {
    const current = window.location.pathname.match(/^\/lectures\/\d+(\/.*)?$/);
    if (!current) return;

    const page = current[1] || "";
    const link = event.currentTarget;
    const target = new URL(link.href);
    // The link leads to viewing where the user may not edit the other lecture.
    if ((page === "/edit") !== target.pathname.endsWith("/edit")) return;

    target.pathname = target.pathname.replace(/^(\/lectures\/\d+).*$/, `$1${page}`);
    target.search = window.location.search;
    link.href = target.toString();
  }
}
