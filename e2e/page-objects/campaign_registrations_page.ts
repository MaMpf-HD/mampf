import { Locator, Page } from "../_support/fixtures";

/**
 * Page object for the registrations on the lecture home page (student view).
 * Used in Playwright tests.
 */
export class CampaignRegistrationPage {
  readonly page: Page;
  readonly link: string;

  constructor(page: Page, lectureId: string | number) {
    this.page = page;
    this.link = `/lectures/${lectureId}/home`;
  }

  async goto() {
    await this.page.goto(this.link);
  }

  /**
   * Returns the collapsed row of an open campaign.
   */
  campaign(title: string): Locator {
    return this.page.getByTestId("registration-campaign").filter({
      has: this.page.getByRole("heading", { name: title }),
    });
  }

  /**
   * Unfolds an open campaign by clicking its summary.
   */
  async openCampaign(title: string): Promise<Locator> {
    const campaign = this.campaign(title);
    await campaign.getByRole("heading", { name: title }).click();
    return campaign;
  }

  /**
   * Returns the rows under "Your participation" that mention the text.
   */
  participation(text: string | RegExp): Locator {
    return this.page.getByTestId("participation-row").filter({ hasText: text });
  }

  registerButtons(scope: Locator | Page = this.page): Locator {
    return scope.getByRole("button", { name: /^Register for / });
  }

  async register(scope: Locator | Page = this.page) {
    await this.registerButtons(scope).first().click();
  }

  async withdraw() {
    await this.page.getByRole("button", { name: /^Withdraw from / }).click();
  }
}
