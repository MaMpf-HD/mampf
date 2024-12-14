// https://on.cypress.io/custom-commands
import BackendCaller from "./backend_caller";

Cypress.Commands.add("getBySelector", (selector, ...args) => {
  return cy.get(`[data-cy=${selector}]`, ...args);
});

/**
 * Expects the subject to be an anchor element `<a>` with a target attribute set
 * to "_blank", such that the link opens in a new tab.
 * Since we cannot access the new tab in Cypress tests, we remove the target
 * attribute from the link and instead just follow the link in the same tab
 * to continue testing.
 */
Cypress.Commands.add("clickExpectNewTab", { prevSubject: true }, ($subject, args) => {
  const errMsg = "Expected subject to be an anchor element";
  expect($subject.is("a"), errMsg).to.be.true;

  cy.wrap($subject).should("have.attr", "target", "_blank");
  return cy.wrap($subject).invoke("removeAttr", "target").click(args);
});

Cypress.Commands.add("assertCopiedToClipboard", (_expectedText) => {
  cy.fail("Not implemented yet");

  // An old method would consist of something like this:
  // adapted from https://stackoverflow.com/a/69571115
  // and https://stackoverflow.com/a/33928558

  //////////////////////////////////////////////////////////////////////////////
  // NEW PROPOSED SOLUTION for the new Clipboard API
  //////////////////////////////////////////////////////////////////////////////

  // TODO (clipboard): We currently use the obsolete clipboard API from browsers,
  // i.e. document.execCommand("copy") via the clipboard.js library.
  // There's a new Clipboard API that is supported by modern browsers.
  // Once we switch to that API, use the following code to test copying to
  // the clipboard. Also see this GitHub issue for more information:
  // https://github.com/cypress-io/cypress/issues/2752
  //
  // Note that another option to test the clipboard content then would be
  // https://github.com/cypress-io/cypress/issues/2752#issuecomment-1039285381
  // which wouldn't even require requesting permissions but might have its
  // own limitations.

  // Request clipboard permissions
  // by https://stackoverflow.com/a/73329952/9655481
  // Note that this won't work by default in a non-secure context (http), so we need to
  // pass the flag --unsafely-treat-insecure-origin-as-secure=http://mampf:3000
  // to the browser when starting it (see the cypress config)
  // cy.wrap(Cypress.automation("remote:debugger:protocol", {
  //   command: "Browser.grantPermissions",
  //   params: {
  //     permissions: ["clipboardReadWrite", "clipboardSanitizedWrite"],
  //   },
  // }));

  // Make sure clipboard permissions were granted
  // https://stackoverflow.com/questions/61650737/how-to-fetch-copied-to-clipboard-content-in-cypress/73329952#comment137190789_69571115
  // cy.window().its("navigator.permissions")
  //   .then(api => api.query({ name: "clipboard-read" }))
  //   .its("state").should("equal", "granted");

  // https://stackoverflow.com/a/75928308/
  // cy.window().its("navigator.clipboard")
  //   .then(clip => clip.readText())
  //   .should("equal", expectedText);
});

Cypress.Commands.add("isValidDate", (date) => {
  // https://stackoverflow.com/a/1353711/
  return date instanceof Date && !isNaN(date);
});

////////////////////////////////////////////////////////////////////////////////
// Custom commands for backend interaction
////////////////////////////////////////////////////////////////////////////////

Cypress.Commands.add("cleanDatabase", () => {
  return BackendCaller.callCypressRoute("database_cleaner", "cy.cleanDatabase()", {});
});

beforeEach(() => {
  cy.cleanDatabase();
});

Cypress.Commands.add("createUser", (role) => {
  if (!["admin", "editor", "teacher", "generic", "tutor"].includes(role)) {
    throw new Error(`Invalid role: ${role}`);
  }
  return BackendCaller.callCypressRoute("user_creator", "cy.createUser()", { role: role });
});

Cypress.Commands.add("login", (user) => {
  return cy.request({
    method: "POST",
    url: "/users/sign_in",
    form: true,
    failOnStatusCode: true,
    body: {
      "user[email]": user.email,
      "user[password]": user.password,
    },
  }).then((response) => {
    expect(response.status).to.eq(200);
  });
});

Cypress.Commands.add("logout", () => {
  return cy.request({
    method: "DELETE",
    url: "/users/sign_out",
    form: true,
    failOnStatusCode: true,
  }).then((response) => {
    expect(response.status).to.eq(204);
  });
});

Cypress.Commands.add("createUserAndLogin", (role) => {
  return cy.createUser(role).then((user) => {
    cy.login({ email: user.email, password: user.password }).then((_) => {
      cy.wrap(user);
    });
  });
});

Cypress.Commands.add("i18n", (key, substitutions) => {
  return BackendCaller.callCypressRoute("i18n", "cy.i18n()",
    { i18n_key: key, substitutions: substitutions });
});
