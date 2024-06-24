/**
 * Helper to access FactoryBot factories from Cypress tests.
 *
 * It calls the /factories endpoint (only available in a testing environment)
 * with the given arguments that get passed to respective Ruby on Rails
 * FactoryBot methods.
 */
class FactoryBot {
  constructor() {
  }

  create(...args) {
    return cy.request({
      url: "/factories",
      method: "post",
      form: true,
      failOnStatusCode: false,
      body: args,
    }).then((res) => {
      if (res.status === 201)
        return res.body;

      let errorMsg = `FactoryBot.create() failed: ${res.body.error}.`;
      errorMsg += `\n\nStacktrace:\n${res.body.stacktrace}`;
      throw new Error(errorMsg);
    });
  }
}

export default new FactoryBot();
