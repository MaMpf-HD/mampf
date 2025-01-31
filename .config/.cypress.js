module.exports = {
  e2e: {
    // Base URL is set via Docker environment variable
    viewportHeight: 1000,
    viewportWidth: 1400,

    // https://docs.cypress.io/app/references/experiments#End-to-End-Testing
    experimentalRunAllSpecs: true,

    // https://docs.cypress.io/api/plugins/browser-launch-api#Changing-browser-preferences
    setupNodeEvents(on, _config) {
      on("before:browser:launch", (browser, launchOptions) => {
        if (browser.family === "chromium" && browser.name !== "electron") {
          // auto open devtools
          launchOptions.args.push("--auto-open-devtools-for-tabs");

          // TODO (clipboard): We use the obsolete clipboard API from browsers, i.e.
          // document.execCommand("copy"). There's a new Clipboard API that is supported
          // by modern browsers. Once we switch to that API, use the following code
          // to allow requesting permission (clipboard permission) in a non-secure
          // context (http). Remaining TODO in this case: search for the equivalent
          // flag in Firefox & Electron (if we also want to test them).
          // launchOptions.args.push("--unsafely-treat-insecure-origin-as-secure=http://mampf:3000");
        }

        if (browser.family === "firefox") {
          // auto open devtools
          launchOptions.args.push("-devtools");
        }

        if (browser.name === "electron") {
          // auto open devtools
          launchOptions.preferences.devTools = true;
        }

        return launchOptions;
      });
    },
  },
};
