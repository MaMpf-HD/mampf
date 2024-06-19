// CypressOnRails: Don't remove these commands (!)
Cypress.Commands.add("appCommands", function (body) {
  Object.keys(body).forEach(key => body[key] === undefined ? delete body[key] : {});
  const log = Cypress.log({ name: "APP", message: body, autoEnd: false });
  return cy.request({
    method: "POST",
    url: "/__e2e__/command",
    body: JSON.stringify(body),
    headers: {
      "Content-Type": "application/json",
    },
    log: false,
    failOnStatusCode: false,
  }).then((response) => {
    log.end();
    if (response.status !== 201) {
      expect(response.body.message).to.equal("");
      expect(response.status).to.be.equal(201);
    }
    return response.body;
  });
});

Cypress.Commands.add("app", function (name, command_options) {
  return cy.appCommands({ name: name, options: command_options }).then((body) => {
    return body[0];
  });
});

Cypress.Commands.add("appScenario", function (name, options = {}) {
  return cy.app("scenarios/" + name, options);
});

Cypress.Commands.add("appEval", function (code) {
  return cy.app("eval", code);
});

Cypress.Commands.add("appFactories", function (options) {
  return cy.app("factory_bot", options);
});

Cypress.Commands.add("appFixtures", function (options) {
  cy.app("activerecord_fixtures", options);
});

////////////////////////////////////////////////////////////////////////////////
// Customizations
////////////////////////////////////////////////////////////////////////////////

beforeEach(() => {
  cy.app("clean"); // also see cypress/app_commands/clean.rb
});

Cypress.Commands.add("dragTo", { prevSubject: "element" }, (subject, targetEl) => {
  cy.wrap(subject).trigger("dragstart");
  cy.get(targetEl).trigger("drop");
});

// https://github.com/shakacode/cypress-on-rails/issues/16#issuecomment-669819936
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
  });
});

Cypress.Commands.add("createUserAndLogin", (role) => {
  if (!["admin", "editor", "teacher", "generic"].includes(role)) {
    throw new Error(`Invalid role: ${role}`);
  }

  // See the scenarios/ folder where these Users are created in Ruby
  cy.appScenario(role);

  cy.login({ email: `${role}@mampf.cypress`, password: "cypress123" });
});
