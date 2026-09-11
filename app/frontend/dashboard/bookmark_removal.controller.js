import RemovalModalController from "./removal_modal.controller";

/**
 * The small "x" on a bookmarked dashboard card: DELETEs the bookmark, which
 * drops the card out of the "Bookmarked" section (and the section itself
 * once it is empty) - see RemovalModalController for the shared modal/fetch
 * plumbing.
 */
export default class extends RemovalModalController {
  bindings() {
    return [["[data-bookmark-removal-confirm]", () => this.confirm()]];
  }

  confirm() {
    this.confirmRemoval(this.urlValue, {
      lectureId: this.lectureIdValue,
      bookmarked: false,
    });
  }
}
