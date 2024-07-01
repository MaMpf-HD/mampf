import BackendCaller from "./backend_caller";

/**
 * Helper to access FactoryBot factories from Cypress tests.
 */
class FactoryBot {
  /**
   * Creates (builds and saves) a record/mock using FactoryBot.
   * @param args The arguments to pass to FactoryBot.create(), e.g.
   * factory name, traits, and attributes. Pass them in as separated
   * string arguments. Attributes should be passed as an object.
   * @returns The FactoryBot.create() response
   *
   * @example
   * FactoryBot.create("factory_name", "with_trait", { another_attribute: ".pdf"})
   */
  create(...args) {
    return BackendCaller.callCypressRoute("factories", "FactoryBot.create()", args);
  }
}

export default new FactoryBot();
