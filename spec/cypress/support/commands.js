// // https://on.cypress.io/custom-commands

// beforeEach(() => {
//   cy.app("clean"); // also see cypress/app_commands/clean.rb
// });

// Cypress.Commands.add("dragTo", { prevSubject: "element" }, (subject, targetEl) => {
//   cy.wrap(subject).trigger("dragstart");
//   cy.get(targetEl).trigger("drop");
// });

// // https://github.com/shakacode/cypress-on-rails/issues/16#issuecomment-669819936
// Cypress.Commands.add("login", (user) => {
//   return cy.request({
//     method: "POST",
//     url: "/users/sign_in",
//     form: true,
//     failOnStatusCode: true,
//     body: {
//       "user[email]": user.email,
//       "user[password]": user.password,
//     },
//   });
// });

// Cypress.Commands.add("createUserAndLogin", (role) => {
//   if (!["admin", "editor", "teacher", "generic"].includes(role)) {
//     throw new Error(`Invalid role: ${role}`);
//   }

//   // See the scenarios/ folder where these Users are created in Ruby
//   cy.appScenario(role);

//   cy.login({ email: `${role}@mampf.cypress`, password: "cypress123" });
// });
