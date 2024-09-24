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
   * FactoryBot.create("factory_name").then(res => {res.call.any_rails_method(42)})
   */
  create(...args) {
    const response = BackendCaller.callCypressRoute("factories", "FactoryBot.create()", args);
    return this.#createProxy(response);
  }

  createNoValidate(...args) {
    args.push({ validate: false });
    return this.create(...args);
  }

  /**
   * Wraps the given Cypress response such that arbitrary methods (dynamic methods)
   * can be called on the resulting object.
   */
  #createProxy(obj) {
    const outerContext = this;

    return new Proxy(obj, {
      get: function (target, property, receiver) {
        if (property !== "as" && property !== "then") {
          return Reflect.get(target, property, receiver);
        }

        // Trap the Cypress "as" and "then" methods to allow dynamic method calls
        return function (...asOrThenArgs) {
          if (property === "then") {
            const callback = asOrThenArgs[0];
            asOrThenArgs[0] = function (callbackObj) {
              outerContext.#defineCallProperty(callbackObj);
              return callback(callbackObj);
            };
            return target[property](...asOrThenArgs);
          }

          if (property === "as") {
            return target.as(...asOrThenArgs).then((asResponse) => {
              outerContext.#defineCallProperty(asResponse);
            });
          }

          throw new Error(`Unknown property that should not be wrapped: ${property}`);
        };
      },
    });
  }

  #defineCallProperty(response) {
    const factoryName = response["factory_name"];
    if (!factoryName) {
      let msg = "FactoryBot call response does not contain factory_name key.";
      msg += " Did you really use FactoryBot.create() (or similar) to create the record?";
      throw new Error(msg);
    }

    if (typeof response.id !== "number") {
      let msg = "FactoryBot call response does not contain a valid id key (number).";
      msg += " Did you really use FactoryBot.create() (or similar) to create the record?";
      throw new Error(msg);
    }

    const call = this.#allowDynamicMethods({}, factoryName, response.id);
    response.call = call;
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
