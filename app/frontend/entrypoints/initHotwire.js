// Hotwire: Stimulus
import { Application } from "@hotwired/stimulus";
window.Stimulus = Application.start();

import LectureSidebarController from "~/lectures/show/_sidebar.controller.js";
window.Stimulus.register("lecture-sidebar", LectureSidebarController);

import LectureTabsController from "~/lectures/edit/tabs/lecture_tabs.controller.js";
window.Stimulus.register("lecture-tabs", LectureTabsController);

import SearchFormController from "~/_components/search_form/search_form.controller.js";
window.Stimulus.register("search-form", SearchFormController);

import FlashMessagesController from "~/flash/_messages.controller.js";
window.Stimulus.register("flash-messages", FlashMessagesController);

// Hotwire: Turbo
import "@hotwired/turbo-rails";
// These two fixes were originally used with Turbolinks.
// They might not be needed with Turbo anymore.
import "~/js/_turbo_fix_bootstrap_modal";
import "~/js/_turbo_fix_selectize";
