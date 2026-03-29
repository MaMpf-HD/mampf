import { Page } from "../_support/fixtures";

/**
 * Page object for campaign registration page (student view). Used in Playwright tests.
 */
export class CampaignRegistrationPage {
  readonly page: Page;
  readonly link: string;

  constructor(page: Page, lectureId: string | number) {
    this.page = page;
    this.link = `lectures/${lectureId}/campaign_registrations`;
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
