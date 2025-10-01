import "~/entrypoints/jQueryGlobal";

// Bootstrap must be imported AFTER jQuery for Bootstrap-jQuery plugins to work,
// e.g. $(".modal").modal("show")
import "bootstrap";
import "~/js/bootstrapModals";
import "~/js/bootstrapPopovers";

// Rails UJS in principle not needed for Turbo anymore. We keep it in the
// transition phase.
// https://github.com/hotwired/turbo-rails/blob/main/UPGRADING.md#upgrading-from-rails-ujs--turbolinks-to-turbo
// https://github.com/rails/rails/issues/49499#issuecomment-1749086834
import Rails from "@rails/ujs";

import "./initHotwire.js";

import "@rails/actiontext";
import * as ActiveStorage from "@rails/activestorage";

import "@popperjs/core";
import "trix";

Rails.start(); // Rails UJS
ActiveStorage.start();

import "~/js/masonry_grid";

// Custom JS needed on every page
import "~/js/main.coffee";
import "~/js/pwa_windows";
import "~/js/reload";
import "~/js/thyme/attributes";
import "./additional.js";

import { WidgetInstance } from "friendly-challenge";

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
