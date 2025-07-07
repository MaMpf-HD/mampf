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
