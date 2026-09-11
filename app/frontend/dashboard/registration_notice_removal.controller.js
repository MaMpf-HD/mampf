import RemovalModalController from "./removal_modal.controller";

/**
 * The small "x" on a rejected-registration dashboard card. It offers two
 * outcomes: keep the lecture as a plain bookmark, or remove it from the
 * dashboard entirely. Either way the rejected registration is only dismissed
 * (hidden), never deleted - see Registration::UserRegistration#dismiss! and
 * RemovalModalController for the shared modal/fetch plumbing.
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
