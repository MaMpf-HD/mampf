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
    const response = BackendCaller.callCypressRoute("factories", "FactoryBot.create()", args);
    return this.#createProxy(response);
  }

  createNoValidate(...args) {
    args.push({ validate: false });
    return this.create(...args);
  }

  #createProxy(object) {
    return new Proxy(object, {
      get: function (target, property, receiver) {
        // Trap the Cypress "as" method to add dynamic methods to the object.
        if (property === "as") {
          return function (...args) {
            // args[0] will be "xyz" if you do <cypress object>.as("xyz")
            target.as(...args).then((response) => {
              response.qed = () => {
                console.log("qed");
              };
            });
          };
        }
        return Reflect.get(target, property, receiver);
      },
    });
  }
}

export default new FactoryBot();
