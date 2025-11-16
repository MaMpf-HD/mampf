import { APIRequestContext } from "@playwright/test";
import { User } from "./auth";
import { callBackend } from "./backend";

/**
 * Helper to access FactoryBot factories from within Playwright tests.
 */
export class FactoryBot {
  context: APIRequestContext;

  constructor(context: APIRequestContext) {
    this.context = context;
  }

  /**
   * Creates (builds and saves) a record/mock using FactoryBot.
   *
   * @param factoryName The name of the factory to create, e.g. "lecture".
   * @param traits Optional array of traits to apply to the factory, e.g. ["released_for_all"].
   * @param args Optional attributes to override on the factory, passed as an object.
   *
   * @returns A FactoryBotObject representing the created record.
   *
   * @examples
   * const lecture = await factory.create("lecture", ["released_for_all"]);
   * const tutorial = await factory.create("tutorial", [],
   *  { lecture_id: lecture.id, tutor_ids: [tutor1.id, tutor2.id] });
   */
  async create(factoryName: string, traits?: string[], args?: Record<string, any>): Promise<FactoryBotObject> {
    const payload = {
      factory_name: factoryName,
      traits: traits || [],
      args: args || {},
    };
    const data = await callBackend(this.context, "factories_playwright", payload);
    return new FactoryBotObject(this.context, factoryName, data);
  }

  async createNoValidate(factoryName: string, traits?: string[], args?: Record<string, any>): Promise<FactoryBotObject> {
    if (!args) {
      args = {};
    }
    args.validate = false;
    return await this.create(factoryName, traits, args);
  }
}

export class FactoryBotObject {
  private context: APIRequestContext;
  private factoryName: string;
  private factoryId: number;
  [key: string]: any; // for dynamic property access without TypeScript errors

  constructor(context: APIRequestContext, factoryName: string, data: any) {
    this.context = context;
    this.factoryName = factoryName;
    this.factoryId = data.id;
    Object.assign(this, data);
  }

  /**
   * Calls a method on a remote factory instance via the backend API.
   *
   * @param methodName The name of the instance method to invoke on the factory.
   * @param user Optional user to pass as the first argument to the method.
   * @param args Arguments to pass to the remote method.
   *
   * @returns A promise that resolves with the backend's result for the invoked method.
   * @throws Will reject if the backend call fails or the backend returns an error.
   *
   * @example
   * const lecture = await factory.create("lecture", ["released_for_all"]);
   * const title = await lecture.__call("title");
   */
  async __call(methodName: string, user?: User, ...args: any[]): Promise<any> {
    const payload = {
      factory_name: this.factoryName,
      instance_id: this.factoryId,
      method_name: methodName,
      method_args: args,
      user_id: user ? user.id : null,
    };
    const result = await callBackend(this.context, "factories_playwright/call_instance_method", payload);
    return result;
  }
}
