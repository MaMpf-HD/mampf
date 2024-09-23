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
    const response = BackendCaller.callCypressRoute("factories", "FactoryBot.create()", args);
    return this.#createProxy(response);
  }

  createNoValidate(...args) {
    args.push({ validate: false });
    return this.create(...args);
  }

  #createProxy(object) {
    const outerContext = this;
    return new Proxy(object, {
      get: function (target, property, receiver) {
        // Proxy the Cypress "as" method to add dynamic methods to the object.
        if (property === "as") {
          return function (...args) {
            return target.as(...args).then(function (result) {
              return outerContext.#addDynamicMethods(result);
            });
          };
        }
        return Reflect.get(target, property, receiver);
      },
    });
  }

  #addDynamicMethods(object) {
    return new Proxy(object, {
      get(target, property, receiver) {
        // If the property does not exist, define it as a new function
        if (!(property in target) && property !== "then") {
          target[property] = function () {
            console.log(`Method ${property} has been dynamically created and invoked!`);
          };
        }
        return Reflect.get(target, property, receiver);
      },
    });
  }
}

export default new FactoryBot();
