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

  async save() {
    await this.page.getByRole("button", { name: "save your changes" }).click();
    // go back to profile page after redirect
    await this.goto();
  }
}
