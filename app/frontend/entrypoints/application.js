import "~/entrypoints/jQueryGlobal";

// Bootstrap must be imported AFTER jQuery for bootstrap jQuery plugins to work,
// e.g. $(".modal").modal("show")
import "bootstrap";
import "~/js/bootstrap_modal_turbolinks_fix";
import "~/js/bootstrapPopovers";

import "@rails/actiontext";
import * as ActiveStorage from "@rails/activestorage";
import Turbolinks from "turbolinks";

import "@popperjs/core";
import "gems/clipboard-rails/vendor/assets/javascripts/clipboard";
import "trix";

// Custom JS needed on every page
import "~/js/_selectize_turbolinks_fix";
import "~/js/main.coffee";
import "~/js/pwa_windows";
import "~/js/thyme/attributes";

// TODO: use vite_javascript_tag at the respective files instead of importing
// everything here. This is just a temporary solution during the Vite migration.
import "~/js/administration.coffee";
import "~/js/announcements.coffee";
import "~/js/answers.coffee";
import "~/js/chapters.coffee";
import "~/js/clickers.coffee";
import "~/js/copy_and_paste_button";
import "~/js/courses.coffee";
import "~/js/erdbeere.coffee";
import "~/js/file_upload.coffee";
import "~/js/items.coffee";
import "~/js/katex.coffee";
import "~/js/lectures";
import "~/js/lessons.coffee";
import "~/js/mampf_routes";
import "~/js/media.coffee";
import "~/js/notifications.coffee";
import "~/js/questions.coffee";
import "~/js/quizzes.coffee";
import "~/js/referrals.coffee";
import "~/js/registration.coffee";
import "~/js/reload";
import "~/js/remarks.coffee";
import "~/js/search_tags";
import "~/js/sections.coffee";
import "~/js/submissions.coffee";
import "~/js/tags.coffee";
import "~/js/talks.coffee";
import "~/js/terms.coffee";
import "~/js/tex_preview.coffee";
import "~/js/tutorials.coffee";
import "~/js/upload.coffee";
import "~/js/users.coffee";
import "~/js/vertices.coffee";
import "~/js/watchlists.coffee";

Turbolinks.start();
ActiveStorage.start();

import { WidgetInstance } from "friendly-challenge";
import "~/js/masonry_grid";

document.addEventListener("turbolinks:load", function () {
  var doneCallback, element, options;

  doneCallback = function (solution) {
    console.log(solution);
    document.querySelector("#register-user").disabled = false;
  };
  const errorCallback = (err) => {
    console.log("There was an error when trying to solve the Captcha.");
    console.log(err);
  };
  element = document.querySelector("#captcha-widget");
  if (element != null) {
    options = {
      doneCallback: doneCallback,
      errorCallback,
      puzzleEndpoint: $("#captcha-widget").data("captcha-url"),
      startMode: "auto",
      language: $("#captcha-widget").data("lang"),
    };
    console.log(options);
    new WidgetInstance(element, options);
    // DO not uncomment, evil
    //    widget.reset();
  }
});
