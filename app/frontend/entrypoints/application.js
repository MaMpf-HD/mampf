// To see this message, add the following to the `<head>` section in your
// views/layouts/application.html.erb
//
//    <%= vite_client_tag %>
//    <%= vite_javascript_tag 'application' %>
console.log("Vite ⚡️ Rails");

// If using a TypeScript entrypoint file:
//     <%= vite_typescript_tag 'application' %>
//
// If you want to use .jsx or .tsx, add the extension:
//     <%= vite_javascript_tag 'application.jsx' %>

console.log("Visit the guide for more information: ", "https://vite-ruby.netlify.app/guide/rails");

// Example: Load Rails libraries in Vite.
//
// import * as Turbo from '@hotwired/turbo'
// Turbo.start()
//
// import ActiveStorage from '@rails/activestorage'
// ActiveStorage.start()
//
// // Import all channels.
// const channels = import.meta.globEager('./**/*_channel.js')

// Example: Import a stylesheet in app/frontend/index.css
// import '~/index.css'

import { WidgetInstance } from "friendly-challenge";

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

import "@rails/actiontext";
import * as ActiveStorage from "@rails/activestorage";
import * as bootstrap from "bootstrap";
import "~/js/_selectize_turbolinks_fix";
import "~/js/administration.coffee";
import "~/js/announcements.coffee";
import "~/js/answers.coffee";

import "gems/clipboard-rails/vendor/assets/javascripts/clipboard";
import "~/js/bootstrap_modal_turbolinks_fix";
import "~/js/bootstrap_popovers";
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
import "~/js/main.coffee";
import "~/js/mampf_routes";
import "~/js/masonry_grid";
import "~/js/media.coffee";
import "~/js/notifications.coffee";
import "@popperjs/core";
import "gems/turbolinks-source/lib/assets/javascripts/turbolinks";
import "trix";
import "~/js/pwa_windows";
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

/**
 * THYME-related scripts.
 */
import "~/js/thyme/annotations/annotation";
import "~/js/thyme/annotations/annotation_area";
import "~/js/thyme/annotations/annotation_manager";
import "~/js/thyme/annotations/category";
import "~/js/thyme/annotations/category_enum";
import "~/js/thyme/annotations/subcategory";
import "~/js/thyme/annotations/url_annotation_opener";
import "~/js/thyme/attributes";
import "~/js/thyme/chapter_manager";
import "~/js/thyme/components/add_item_button";
import "~/js/thyme/components/add_reference_button";
import "~/js/thyme/components/add_screenshot_button";
import "~/js/thyme/components/annotation_button";
import "~/js/thyme/components/annotation_category_toggle";
import "~/js/thyme/components/annotations_toggle";
import "~/js/thyme/components/component";
import "~/js/thyme/components/full_screen_button";
import "~/js/thyme/components/ia_back_button";
import "~/js/thyme/components/ia_button";
import "~/js/thyme/components/ia_close_button";
import "~/js/thyme/components/mute_button";
import "~/js/thyme/components/next_chapter_button";
import "~/js/thyme/components/play_button";
import "~/js/thyme/components/previous_chapter_button";
import "~/js/thyme/components/seek_bar";
import "~/js/thyme/components/speed_selector";
import "~/js/thyme/components/time_button";
import "~/js/thyme/components/volume_bar";
import "~/js/thyme/control_bar_hider";
import "~/js/thyme/display_manager";
import "~/js/thyme/heatmap";
import "~/js/thyme/key_shortcuts";
import "~/js/thyme/metadata_manager";
import "~/js/thyme/resizer";
import "~/js/thyme/thyme_editor";
import "~/js/thyme/thyme_feedback";
import "~/js/thyme/thyme_player";
import "~/js/thyme/utility";

ActiveStorage.start();
console.log(bootstrap);
