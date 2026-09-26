import { Controller } from "@hotwired/stimulus";

/**
 * Carries the open tab of the lecture edit page over when switching to
 * another lecture's edit page. The tab lives only in the current URL, since
 * the tabs update it on the client (see lecture_tabs.controller.js).
 */
export default class extends Controller {
  keepTab(event) {
    const tab = new URL(window.location).searchParams.get("tab");
    if (!tab) return;

    const url = new URL(event.currentTarget.href);
    url.searchParams.set("tab", tab);
    event.currentTarget.href = url.toString();
  }
}
