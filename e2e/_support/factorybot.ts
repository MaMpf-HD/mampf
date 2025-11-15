import { APIRequestContext } from "@playwright/test";
import { callBackend } from "./backend";

/**
 * Helper to access FactoryBot factories from Cypress tests.
 */
export class FactoryBot {
  context: APIRequestContext;

  constructor(context: APIRequestContext) {
    this.context = context;
  }

  /**
   * Creates (builds and saves) a record/mock using FactoryBot.
   *
   * @param args The arguments to pass to FactoryBot.create(), e.g.
   * factory name, traits, and attributes. Pass them in as separated
   * string arguments. Attributes should be passed as an object.
   * You are also able to call instance methods on the created record later.
   *
   * @returns The FactoryBot.create() response.
   *
   * @examples
   * FactoryBot.create("factory_name", "with_trait", { another_attribute: ".pdf"})
   * FactoryBot.create("factory_name").then(res => {res.call.any_rails_method(42)})
   * FactoryBot.create("tutorial",
   *  { lecture_id: this.lecture.id, tutor_ids: [this.tutor1.id, this.tutor2.id] })
   */
  async create(...args: any[]): Promise<any> {
    return await callBackend(this.context, "factories", args);
  }

  async createNoValidate(...args: any[]): Promise<any> {
    args.push({ validate: false });
    return await this.create(...args);
  }
}
