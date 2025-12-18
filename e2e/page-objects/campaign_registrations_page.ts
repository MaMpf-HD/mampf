import { Page } from "../_support/fixtures";

/**
 * Missing top-level docstring, please formulate one yourself 😁
 */
export class CampaignRegistrationPage {
  readonly page: Page;
  readonly link: string;

  constructor(page: Page, campaignId: string | number) {
    this.page = page;
    this.link = `/campaign_registrations/${campaignId}`;
  }

  async goto() {
    await this.page.goto(this.link);
  }

  async register() {
    await this.page.getByRole("button", { name: "Register now" }).click();
  }

  async withdraw() {
    await this.page.getByRole("button", { name: "Withdraw" }).click();
  }
}
