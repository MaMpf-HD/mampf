// Hotwired: Stimulus
import { Application } from "@hotwired/stimulus";
import LectureSidebarController from "~/js/lecture_sidebar.controller";
window.Stimulus = Application.start();
window.Stimulus.register("lecture-sidebar", LectureSidebarController);

// Hotwired: Turbo
import "@hotwired/turbo-rails";
// These two fixes were originally used with Turbolinks.
// They might not be needed with Turbo anymore.
import "~/js/_turbo_fix_bootstrap_modal";
import "~/js/_turbo_fix_selectize";
