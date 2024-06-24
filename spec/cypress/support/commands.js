// https://on.cypress.io/custom-commands
import BackendCaller from "./backend_caller";

Cypress.Commands.add("cleanDatabase", () => {
  return BackendCaller.callCypressRoute("database_cleaner", "Database cleaner", {});
});

beforeEach(() => {
  cy.cleanDatabase();
});

Cypress.Commands.add("createUser", (role) => {
  if (!["admin", "editor", "teacher", "generic"].includes(role)) {
    throw new Error(`Invalid role: ${role}`);
  }
  return BackendCaller.callCypressRoute("user_creator", "FactoryBot.createUser()", { role: role });
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
  });
});

Cypress.Commands.add("createUserAndLogin", (role) => {
  cy.createUser(role);
  cy.login({ email: `${role}@mampf.cypress`, password: "cypress123" });
});
