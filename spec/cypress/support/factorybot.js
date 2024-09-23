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
        if (property !== "as") {
          return Reflect.get(target, property, receiver);
        }

        // Trap the Cypress "as" method
        return function (...asArgs) {
          return target.as(...asArgs).then((response) => {
            const responseProxy = new Proxy(response, {
              get: function (resTarget, resProperty, resReceiver) {
                console.log(resProperty);
                if (!(resProperty in resTarget) && resProperty !== "then") {
                  // If the property does not exist, define it as a new function
                  resTarget[resProperty] = function () {
                    console.log(`Method "${resProperty}" has been dynamically created!`);
                  };
                }
                // Return the property (method)
                return Reflect.get(resTarget, resProperty, resReceiver);
              },
            });
            // Overwrite the original response with the proxy
            cy.wrap(responseProxy).as(...asArgs);

            return target;
          });
        };
      },
    });
  }
}

export default new FactoryBot();
