import { Page } from "../_support/fixtures";

export class ProfilePage {
  readonly page: Page;
  readonly link = "/profile/edit";

  constructor(page: Page) {
    this.page = page;
  }

  async goto() {
    await this.page.goto(this.link);
  }
}
