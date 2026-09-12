import RemovalModalController from "./removal_modal.controller";

/** The "x" on a rejected-registration dashboard card.
 *
 * Dismisses the notice (see Registration::UserRegistration#dismiss!),
 * keeping or dropping the bookmark.
 */
export default class extends RemovalModalController {
  bindings() {
    return [
      ["[data-registration-notice-removal-keep-bookmarked]", () => this.confirm(true)],
      ["[data-registration-notice-removal-remove-entirely]", () => this.confirm(false)],
    ];
  }

  confirm(keepBookmarked) {
    const url = `${this.urlValue}?keep_bookmarked=${keepBookmarked}`;
    this.confirmRemoval(url, {
      lectureId: this.lectureIdValue,
      bookmarked: keepBookmarked,
    });
  }
}
