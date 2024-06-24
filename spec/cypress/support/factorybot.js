import BackendCaller from "./backend_caller";

/**
 * Helper to access FactoryBot factories from Cypress tests.
 *
 * It calls the /factories endpoint (only available in a testing environment)
 * with the given arguments that get passed to respective Ruby on Rails
 * FactoryBot methods.
 */
class FactoryBot {
  create(...args) {
    return BackendCaller.callCypressRoute("factories", "FactoryBot.create()", args);
  }
}

export default new FactoryBot();
