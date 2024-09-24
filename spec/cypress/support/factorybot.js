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

  #createProxy(obj) {
    const outerContext = this;

    return new Proxy(obj, {
      get: function (target, property, receiver) {
        if (property !== "as") {
          return Reflect.get(target, property, receiver);
        }

        // Trap the Cypress "as" method
        return function (...asArgs) {
          return target.as(...asArgs).then((response) => {
            const call = outerContext.#allowDynamicMethods({});
            response.call = call;
            return target;
          });
        };
      },
    });
  }

  #allowDynamicMethods(obj) {
    return new Proxy(obj, {
      get: function (target, property, receiver) {
        // If the property does not exist, define it as a new function
        if (!(property in target)) {
          target[property] = function () {
            console.log(`Method "${property}" has been dynamically created!`);
          };
        }
        return Reflect.get(target, property, receiver);
      },
    });
  }
}

export default new FactoryBot();
