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
   * You are also able to call instance methods on the created record later.
   * @returns The FactoryBot.create() response.
   * @examples
   * FactoryBot.create("factory_name", "with_trait", { another_attribute: ".pdf"})
   * FactoryBot.create("factory_name").as("alias"); this.alias.call.instance_method();
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
            const factoryName = response["factory_name"];
            if (!factoryName) {
              let msg = "FactoryBot call response does not contain factory_name key.";
              msg += " Did you really use FactoryBot.create() (or similar) to create the record?";
              throw new Error(msg);
            }
            if (typeof response.id !== "number") {
              let msg = "FactoryBot call response does not contain a valid id key.";
              msg += " Did you really use FactoryBot.create() (or similar) to create the record?";
              throw new Error(msg);
            }
            const call = outerContext.#allowDynamicMethods({}, factoryName, response.id);
            response.call = call;
            return target;
          });
        };
      },
    });
  }

  #allowDynamicMethods(obj, factoryName, instanceId) {
    return new Proxy(obj, {
      get: function (target, property, receiver) {
        // If the property does not exist, define it as a new function
        if (!(property in target)) {
          target[property] = function () {
            const payload = {
              factory_name: factoryName,
              instance_id: instanceId,
              method_name: property,
              method_args: Array.from(arguments),
            };
            return BackendCaller.callCypressRoute("factories/call_instance_method",
              `FactoryBot.create().call.${property}()`, payload);
          };
        }
        return Reflect.get(target, property, receiver);
      },
    });
  }
}

export default new FactoryBot();
