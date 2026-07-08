import { expect, Page } from "../_support/fixtures";

export class LecturePage {
  readonly page: Page;
  readonly link: string;

  constructor(page: Page, lectureId: number) {
    this.page = page;
    this.link = `/lectures/${lectureId}`;
  }

  async goto() {
    await this.page.goto(this.link);
  }

  async gotoEdit() {
    await this.page.goto(`${this.link}/edit`);
  }

  async subscribe() {
    await this.goto();
    const subscribeButton = this.page.getByRole("button", { name: "subscribe event series" });
    await subscribeButton.click();
    await expect(subscribeButton).toHaveCount(0);
  }
}
