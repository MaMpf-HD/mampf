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
    return new Proxy(object, {
      get: function (target, property, receiver) {
        // Trap the Cypress "as" method to add dynamic methods to the object.
        if (property === "as") {
          return function (...args) {
            // args[0] will be "xyz" if you do <cypress object>.as("xyz")
            target.as(...args).then((result) => {
              // Add dynamic methods to the result object
              const resultProxy = new Proxy(result, {
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

              // In-place wrap result with a Proxy (normal assignment won't work)
              Object.assign(result, resultProxy);

              return result;
            });
          };
        }
        return Reflect.get(target, property, receiver);
      },
    });
  }
}

export default new FactoryBot();
