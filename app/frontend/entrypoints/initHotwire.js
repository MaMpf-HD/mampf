// Hotwire: Stimulus
import { Application } from "@hotwired/stimulus";
window.Stimulus = Application.start();

import LectureSidebarController from "~/lectures/show/_sidebar.controller.js";
window.Stimulus.register("lecture-sidebar", LectureSidebarController);
import LectureSwitcherController from "~/lectures/show/switcher.controller.js";
window.Stimulus.register("lecture-switcher", LectureSwitcherController);

import LectureTabsController from "~/lectures/edit/tabs/lecture_tabs.controller.js";
window.Stimulus.register("lecture-tabs", LectureTabsController);

import LectureHomeFormController from "~/lectures/edit/home_form.controller.js";
window.Stimulus.register("lecture-home-form", LectureHomeFormController);

import MediaButtonSortController from "~/lectures/edit/media/media_button_sort.controller.js";
window.Stimulus.register("media-button-sort", MediaButtonSortController);

import SearchFormController from "~/_components/search_form/search_form.controller.js";
window.Stimulus.register("search-form", SearchFormController);

import ModalController from "~/modal/modal.controller.js";
window.Stimulus.register("modal", ModalController);

import TurboModalController from "~/modal/turbo_modal.controller.js";
window.Stimulus.register("turbo-modal", TurboModalController);

import FlashMessagesController from "~/flash/_messages.controller.js";
window.Stimulus.register("flash-messages", FlashMessagesController);

import FeedbackFormController from "~/feedbacks/form/_form.controller.js";
window.Stimulus.register("feedback", FeedbackFormController);

import VignettesQuestionController from "~/vignettes/slides/form/question/_question.controller.js";
window.Stimulus.register("vignettes-question", VignettesQuestionController);

import VignettesMultipleChoiceController from "~/vignettes/slides/form/question/types/_multiple_choice.controller.js";
window.Stimulus.register("vignettes-multiple-choice", VignettesMultipleChoiceController);

import WatchlistSortableController from "~/watchlists/sortable.controller.js";
window.Stimulus.register("watchlist-sortable", WatchlistSortableController);

import SubmitOnChangeController from "~/controllers/submit_on_change.controller.js";
window.Stimulus.register("submit-on-change", SubmitOnChangeController);

import VignettesNumberController from "~/vignettes/slides/form/question/types/_number.controller.js";
window.Stimulus.register("vignettes-number", VignettesNumberController);

import VignettesPositionController from "~/vignettes/questionnaires/take/position.controller.js";
window.Stimulus.register("vignettes-position", VignettesPositionController);

import VignettesResumeController from "~/vignettes/questionnaires/index/resume.controller.js";
window.Stimulus.register("vignettes-resume", VignettesResumeController);

import VignettesSlidesSortableController from "~/vignettes/questionnaires/edit/slides_sortable.controller.js";
window.Stimulus.register("vignettes-slides-sortable", VignettesSlidesSortableController);

import VignettesModalAutofocusController from "~/vignettes/questionnaires/new/modal_autofocus.controller.js";
window.Stimulus.register("vignettes-modal-autofocus", VignettesModalAutofocusController);

import VignettesDataCollectionController from "~/vignettes/questionnaires/edit/data_collection.controller.js";
window.Stimulus.register("vignettes-data-collection", VignettesDataCollectionController);

import LectureSearchController from "~/lectures/search/search.controller.js";
window.Stimulus.register("lecture-search", LectureSearchController);

import QuestionCounterController from "~/lectures/quizzes/question_counter.controller.js";
window.Stimulus.register("question-counter", QuestionCounterController);

import AudiencePickerController from "~/student_messages/audience_picker.controller.js";
window.Stimulus.register("audience-picker", AudiencePickerController);

import CoursesEditController from "~/courses/edit/courses_edit.controller.js";
window.Stimulus.register("courses-edit", CoursesEditController);

import PasswordStrengthController from "~/auth/password_strength.controller.js";
window.Stimulus.register("password-strength", PasswordStrengthController);

import RegistrationPolicyFormController from "~/registration/policies/policy_form.controller.js";
window.Stimulus.register("registration-policy-form", RegistrationPolicyFormController);

import SortablePoliciesController from "~/registration/policies/sortable_policies.controller.js";
window.Stimulus.register("sortable-policies", SortablePoliciesController);

import RegisterableTypeHelpController from "~/registration/registerable_type_help.controller.js";
window.Stimulus.register("registerable-type-help", RegisterableTypeHelpController);

import CollapseController from "~/registration/collapse.controller.js";
window.Stimulus.register("collapse", CollapseController);

import BsPopoverController from "~/controllers/bs_popover.controller.js";
window.Stimulus.register("bs-popover", BsPopoverController);

import RowClickController from "~/controllers/row_click.controller.js";
window.Stimulus.register("row-click", RowClickController);

import DatetimepickerController from "~/controllers/datetimepicker.controller.js";
window.Stimulus.register("datetimepicker", DatetimepickerController);

import EnrolledTutorGuardController from "~/tutorials/enrolled_tutor_guard.controller.js";
window.Stimulus.register("enrolled-tutor-guard", EnrolledTutorGuardController);

import CapacityGuardController from "~/roster/capacity_guard.controller.js";
window.Stimulus.register("capacity-guard", CapacityGuardController);

import TutorialRosterPanelController from "~/registration/campaigns/tutorial_roster_panel.controller.js";
window.Stimulus.register("tutorial-roster-panel", TutorialRosterPanelController);

import CampaignDissolveController from "~/registration/campaigns/campaign_dissolve.controller.js";
window.Stimulus.register("campaign-dissolve", CampaignDissolveController);

import RosterDragController from "~/roster/roster_drag.controller.js";
window.Stimulus.register("roster-drag", RosterDragController);

import AutoSubmitFormController from "~/controllers/auto_submit_form.controller.js";
window.Stimulus.register("auto-submit-form", AutoSubmitFormController);

import FileSizeController from "~/controllers/file_size.controller.js";
window.Stimulus.register("file-size", FileSizeController);

import PersonalDataFormController from "~/personal_data/personal_data_form.controller.js";
window.Stimulus.register("personal-data-form", PersonalDataFormController);
import StudyProgramController from "~/personal_data/study_program.controller.js";
window.Stimulus.register("study-program", StudyProgramController);

import ClipboardController from "~/controllers/clipboard.controller.js";
window.Stimulus.register("clipboard", ClipboardController);

import LectureEditController from "~/lectures/edit/lecture_edit.controller.js";
window.Stimulus.register("lecture-edit", LectureEditController);

import LectureSubscribersController from "~/lectures/edit/lecture_subscribers.controller.js";
window.Stimulus.register("lecture-subscribers", LectureSubscribersController);

import UppyUploadController from "~/controllers/uppy_upload.controller.js";
window.Stimulus.register("uppy-upload", UppyUploadController);

import SubmissionUploadController from "~/controllers/submission_upload.controller.js";
window.Stimulus.register("submission-upload", SubmissionUploadController);

import SheetNewsController from "~/submissions/components/sheet_news.controller.js";
window.Stimulus.register("sheet-news", SheetNewsController);

import PreferenceChoicesController from "~/user_registrations/preference_choices.controller.js";
window.Stimulus.register("preference-choices", PreferenceChoicesController);
import RegistrationFoldController from "~/user_registrations/registration_fold.controller.js";
window.Stimulus.register("registration-fold", RegistrationFoldController);
import OptionFilterController from "~/user_registrations/option_filter.controller.js";
window.Stimulus.register("option-filter", OptionFilterController);
import LectureNewsController from "~/lectures/home/lecture_news.controller.js";
window.Stimulus.register("lecture-news", LectureNewsController);
import LectureIntroController from "~/lectures/home/lecture_intro.controller.js";
window.Stimulus.register("lecture-intro", LectureIntroController);
import ParticipationFocusController from "~/lectures/home/participation_focus.controller.js";
window.Stimulus.register("participation-focus", ParticipationFocusController);

import CapacityEditorController from "~/registration/allocations/capacity_editor.controller.js";
window.Stimulus.register("capacity-editor", CapacityEditorController);

import DismissWorkspaceController from "~/registration/allocations/dismiss_workspace.controller.js";
window.Stimulus.register("dismiss-workspace", DismissWorkspaceController);

import SelectizeController from "~/controllers/selectize.controller.js";
window.Stimulus.register("selectize", SelectizeController);

import ProfileController from "~/profile/profile.controller.js";
window.Stimulus.register("profile", ProfileController);

import LectureHighlightsController from "~/lectures/lecture_highlights.controller.js";
window.Stimulus.register("lecture-highlights", LectureHighlightsController);

import DirtyFormController from "~/assessment/dirty_form.controller.js";
window.Stimulus.register("assessments--dirty-form", DirtyFormController);

import PointsPrecisionController from "~/assessment/points_precision.controller.js";
window.Stimulus.register("assessments--points-precision", PointsPrecisionController);

import SchemeFormController from "~/assessment/assessments/scheme_form.controller.js";
window.Stimulus.register("assessments--scheme-form", SchemeFormController);

import AssignmentsCompleteController from "~/assessment/assessments/assignments_complete.controller.js";
window.Stimulus.register("assessments--assignments-complete", AssignmentsCompleteController);

import AchievementFormController from "~/student_performance/achievements/achievement_form.controller.js";
window.Stimulus.register("achievement-form", AchievementFormController);

import CertificationInlineController from "~/student_performance/certifications/certification_inline.controller.js";
window.Stimulus.register("certification-inline", CertificationInlineController);

import ThresholdModeController from "~/student_performance/rules/threshold-mode.controller.js";
window.Stimulus.register("threshold-mode", ThresholdModeController);

import SortableController from "~/assessment/sortable.controller.js";
window.Stimulus.register("sortable", SortableController);

import ParticipationRowController from "~/assessment/participation_row.controller.js";
window.Stimulus.register("participation-row", ParticipationRowController);

import MarkingTableController from "~/assessment/marking_table.controller.js";
window.Stimulus.register("marking-table", MarkingTableController);

import TableFadeController from "~/tutorials/table_fade.controller.js";
window.Stimulus.register("table-fade", TableFadeController);

import ExemptModalController from "~/assessment/exempt_modal.controller.js";
window.Stimulus.register("exempt-modal", ExemptModalController);

import StatusFilterController from "~/tutorials/status_filter.controller.js";
window.Stimulus.register("status-filter", StatusFilterController);
import SelectNavigationController from "~/tutorials/select_navigation.controller.js";
window.Stimulus.register("select-navigation", SelectNavigationController);
import ExamFormController from "~/exams/form.controller.js";
window.Stimulus.register("exams--form", ExamFormController);

import ExamRegistrationSettingsController from "~/exams/registration_settings.controller.js";
window.Stimulus.register("exams--registration-settings", ExamRegistrationSettingsController);

import ExamRegistrationListController from "~/exams/registration_list.controller.js";
window.Stimulus.register("exams--registration-list", ExamRegistrationListController);
import AdministrationIndexCreateButtonsController from "~/administration/index/create_buttons.controller.js";
window.Stimulus.register("administration-index-create-buttons", AdministrationIndexCreateButtonsController);

import MediaDownloadButtonController from "~/media/download_button.controller.js";
window.Stimulus.register("media-download-button", MediaDownloadButtonController);

import LecturesNewFormController from "~/lectures/new/_form.controller.js";
window.Stimulus.register("lectures-new-form", LecturesNewFormController);

import WashiTapeController from "~/dashboard/washi_tape.controller.js";
window.Stimulus.register("washi-tape", WashiTapeController);

import DashboardTermSelectController from "~/dashboard/dashboard_term_select.controller.js";
window.Stimulus.register("dashboard-term-select", DashboardTermSelectController);

import DashboardSectionController from "~/dashboard/dashboard_section.controller.js";
window.Stimulus.register("dashboard-section", DashboardSectionController);

import BookmarkRemovalController from "~/dashboard/bookmark_removal.controller.js";
window.Stimulus.register("bookmark-removal", BookmarkRemovalController);

import RegistrationNoticeRemovalController from "~/dashboard/registration_notice_removal.controller.js";
window.Stimulus.register("registration-notice-removal", RegistrationNoticeRemovalController);

import BookmarkController from "~/lectures/search/bookmark.controller.js";
window.Stimulus.register("bookmark", BookmarkController);

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
