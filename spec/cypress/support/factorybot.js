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
   * You can also pass instance methods as an array of strings.
   * @returns The FactoryBot.create() response. If you added instance methods,
   * the response will be enriched by the results of the instance methods.
   *
   * @examples
   * FactoryBot.create("factory_name", "with_trait", { another_attribute: ".pdf"})
   * FactoryBot.create("factory_name", { instance_methods: ["method_name"] })
   */
  create(...args) {
    return BackendCaller.callCypressRoute("factories", "FactoryBot.create()", args);
  }

  createNoValidate(...args) {
    args.push({ validate: false });
    return this.create(...args);
  }
}

export default new FactoryBot();
