import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["newMedium"];

  changeNewMediumSort(event) {
    const sort = event.target.dataset.sort;
    if (!sort) {
      console.error("No sort type found on tab!");
      return;
    }

    const currentHref = this.newMediumTarget.href;
    const url = new URL(currentHref, window.location.origin);
    url.searchParams.set("sort", sort);
    this.newMediumTarget.href = url.pathname + url.search;
  }
}
