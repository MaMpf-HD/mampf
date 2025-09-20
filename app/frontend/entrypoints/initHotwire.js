// Hotwire: Stimulus
import { Application } from "@hotwired/stimulus";
window.Stimulus = Application.start();

import LectureSidebarController from "~/lectures/show/_sidebar.controller.js";
window.Stimulus.register("lecture-sidebar", LectureSidebarController);

import LectureTabsController from "~/lectures/edit/tabs/lecture_tabs.controller.js";
window.Stimulus.register("lecture-tabs", LectureTabsController);

import SearchFormController from "~/_components/search_form/search_form.controller.js";
window.Stimulus.register("search-form", SearchFormController);

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
