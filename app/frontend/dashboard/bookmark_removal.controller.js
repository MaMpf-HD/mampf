import RemovalModalController from "./removal_modal.controller";

/** The "x" on a bookmarked dashboard card: removes the bookmark. */
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
