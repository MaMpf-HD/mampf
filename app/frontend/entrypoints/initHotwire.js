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

import LectureSearchController from "~/lectures/search/search.controller.js";
window.Stimulus.register("lecture-search", LectureSearchController);

import RegistrationPolicyFormController from "~/registration/policies/policy_form.controller.js";
window.Stimulus.register("registration-policy-form", RegistrationPolicyFormController);

import RegisterableTypeHelpController from "~/registration/registerable_type_help.controller.js";
window.Stimulus.register("registerable-type-help", RegisterableTypeHelpController);

import CohortPurposeController from "~/registration/cohort_purpose.controller.js";
window.Stimulus.register("cohort-purpose", CohortPurposeController);

import CampaignActionController from "~/registration/campaign_action.controller.js";
window.Stimulus.register("campaign-action", CampaignActionController);

import CollapseController from "~/registration/collapse.controller.js";
window.Stimulus.register("collapse", CollapseController);

import BsPopoverController from "~/controllers/bs_popover_controller.js";
window.Stimulus.register("bs-popover", BsPopoverController);

import RowClickController from "~/controllers/row_click.controller.js";
window.Stimulus.register("row-click", RowClickController);

import DatetimepickerController from "~/controllers/datetimepicker_controller.js";
window.Stimulus.register("datetimepicker", DatetimepickerController);

import RosterEnrollmentController from "~/roster/roster_enrollment_controller.js";
window.Stimulus.register("roster-enrollment", RosterEnrollmentController);

import CapacityGuardController from "~/roster/capacity_guard_controller.js";
window.Stimulus.register("capacity-guard", CapacityGuardController);

import RosterFilterController from "~/roster/roster_filter.controller.js";
window.Stimulus.register("roster-filter", RosterFilterController);

import AutoSubmitFormController from "~/controllers/auto_submit_form_controller.js";
window.Stimulus.register("auto-submit-form", AutoSubmitFormController);

import SelectizeController from "~/controllers/selectize_controller.js";
window.Stimulus.register("selectize", SelectizeController);

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
