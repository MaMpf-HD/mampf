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
    const responsePromise = this.page.waitForResponse(response =>
      response.url().includes("main/start"),
    );
    await this.page.getByRole("button", { name: "save your changes" }).click();
    await responsePromise;

    // go back to profile page after redirect
    await this.goto();
  }
}
