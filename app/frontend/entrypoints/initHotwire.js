// Hotwire: Stimulus
import { Application } from "@hotwired/stimulus";
window.Stimulus = Application.start();

import LectureSidebarController from "~/lectures/show/_sidebar.controller.js";
window.Stimulus.register("lecture-sidebar", LectureSidebarController);

import LectureTabsController from "~/lectures/edit/tabs/lecture_tabs.controller.js";
window.Stimulus.register("lecture-tabs", LectureTabsController);

import MediaButtonSortController from "~/lectures/edit/media/media_button_sort.controller.js";
window.Stimulus.register("media-button-sort", MediaButtonSortController);

import SearchFormController from "~/_components/search_form/search_form.controller.js";
window.Stimulus.register("search-form", SearchFormController);

import ModalController from "~/modal/modal.controller.js";
window.Stimulus.register("modal", ModalController);

import FlashMessagesController from "~/flash/_messages.controller.js";
window.Stimulus.register("flash-messages", FlashMessagesController);

import FeedbackFormController from "~/feedbacks/form/_form.controller.js";
window.Stimulus.register("feedback", FeedbackFormController);

import VignettesQuestionController from "~/vignettes/slides/form/question/_question.controller.js";
window.Stimulus.register("vignettes-question", VignettesQuestionController);

import VignettesMultipleChoiceController from "~/vignettes/slides/form/question/types/_multiple_choice.controller.js";
window.Stimulus.register("vignettes-multiple-choice", VignettesMultipleChoiceController);

import VignettesNumberController from "~/vignettes/slides/form/question/types/_number.controller.js";
window.Stimulus.register("vignettes-number", VignettesNumberController);

import RegistrationItemController from "~/registration/item_search_form/_search_form.controller.js";
window.Stimulus.register("registration-item-search", RegistrationItemController);

import TouchedCheckController from "~/registration/touched_check/touched_check.controller.js";
window.Stimulus.register("touched-check", TouchedCheckController);

import RegistrationPolicyFormController from "~/registration/policies/policy_form.controller.js";
window.Stimulus.register("registration-policy-form", RegistrationPolicyFormController);

import BsPopoverController from "~/controllers/bs_popover_controller.js";
window.Stimulus.register("bs-popover", BsPopoverController);

import RowClickController from "~/controllers/row_click.controller.js";
window.Stimulus.register("row-click", RowClickController);

import DatetimepickerController from "~/controllers/datetimepicker_controller.js";
window.Stimulus.register("datetimepicker", DatetimepickerController);

// Hotwire: Turbo
import "@hotwired/turbo-rails";
// These two fixes were originally used with Turbolinks.
// They might not be needed with Turbo anymore.
import "~/js/_turbo_fix_bootstrap_modal";
import "~/js/_turbo_fix_selectize";

/**
 * Adds a new event `turbo:stream-render` that is fired after a Turbo Stream
 * has been rendered (analogous to `turbo:frame-render`).
 *
 * Copied from this thread:
 * https://discuss.hotwired.dev/t/event-to-know-a-turbo-stream-has-been-rendered/1554/25
 *
 * Also see this issue:
 * https://github.com/hotwired/turbo/issues/1289
 */
function addNewStreamRenderEvent() {
  const afterRenderEvent = new Event("turbo:stream-render");
  addEventListener("turbo:before-stream-render", (event) => {
    const originalRender = event.detail.render;

    event.detail.render = function (streamElement) {
      originalRender(streamElement);
      document.dispatchEvent(afterRenderEvent);
    };
  });
}

addNewStreamRenderEvent();

/**
 * Reloads a Turbo Frame by resetting its `src` attribute. Most of the time,
 * you won't need this.
 *
 * We expect a normal HTML element here, not a jQuery object.
 *
 * Taken from: https://github.com/hotwired/turbo/issues/202#issuecomment-795540643
 */
export function reloadTurboFrame(element) {
  if (!(element instanceof HTMLElement)) {
    throw new Error("Element must be an instance of HTMLElement");
  }

  if (!element || !element.src) {
    throw new Error("Element must be a Turbo Frame with a valid 'src' attribute");
  }

  const { src } = element;
  element.src = null;
  element.src = src;
}
