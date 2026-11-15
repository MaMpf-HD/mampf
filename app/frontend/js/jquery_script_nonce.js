import Rails from "@rails/ujs";

/**
 * Runs the script that a jQuery Ajax request gets back with the nonce of the
 * page, as rails-ujs does for the answers to its own requests. jQuery runs
 * them without one, and a Content Security Policy lets a script without a
 * nonce pass only as long as it allows every inline script.
 */
$.ajaxSetup({
  converters: {
    "text script": (script) => {
      $.globalEval(script, { nonce: Rails.cspNonce() });
      return script;
    },
  },
});
