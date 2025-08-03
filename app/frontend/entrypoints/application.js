import "~/entrypoints/jQueryGlobal";

// Bootstrap must be imported AFTER jQuery for Bootstrap-jQuery plugins to work,
// e.g. $(".modal").modal("show")
import "bootstrap";
import "~/js/bootstrapPopovers";

// Rails UJS in principle not needed for Turbo anymore. We keep it in the
// transition phase.
// https://github.com/hotwired/turbo-rails/blob/main/UPGRADING.md#upgrading-from-rails-ujs--turbolinks-to-turbo
import Rails from "@rails/ujs";

import "./initHotwired";

import "@rails/actiontext";
import * as ActiveStorage from "@rails/activestorage";

import "@popperjs/core";
import "trix";

// Custom JS needed on every page
import "~/js/main.coffee";
import "~/js/pwa_windows";
import "~/js/reload";
import "~/js/thyme/attributes";

// TODO: use vite_javascript_tag at the respective files instead of importing
// everything here. This is just a temporary solution during the Vite migration.
import "~/js/copy_and_paste_button";
import "~/js/lectures";
import "~/js/mampf_routes";
import "~/js/search_tags";
import "~/js/talks";

import "~/js/administration.coffee";
import "~/js/announcements.coffee";
import "~/js/answers.coffee";
import "~/js/chapters.coffee";
import "~/js/courses.coffee";
import "~/js/erdbeere.coffee";
import "~/js/file_upload.coffee";
import "~/js/items.coffee";
import "~/js/katex.coffee";
import "~/js/lessons.coffee";
import "~/js/media.coffee";
import "~/js/notifications.coffee";
import "~/js/questions.coffee";
import "~/js/quizzes.coffee";
import "~/js/referrals.coffee";
import "~/js/registration.coffee";
import "~/js/remarks.coffee";
import "~/js/sections.coffee";
import "~/js/submissions.coffee";
import "~/js/tags.coffee";
import "~/js/terms.coffee";
import "~/js/tex_preview.coffee";
import "~/js/tutorials.coffee";
import "~/js/upload.coffee";
import "~/js/users.coffee";
import "~/js/vertices.coffee";
import "~/js/watchlists.coffee";

// Rails UJS
// https://github.com/rails/rails/issues/49499#issuecomment-1749086834
Rails.start();
ActiveStorage.start();

import { WidgetInstance } from "friendly-challenge";
import "~/js/masonry_grid";

document.addEventListener("turbo:load", function () {
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
