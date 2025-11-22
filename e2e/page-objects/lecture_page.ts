import { Page } from "../_support/fixtures";

export class LecturePage {
  readonly page: Page;
  readonly link: string;

  constructor(page: Page, lectureId: number) {
    this.page = page;
    this.link = `/lectures/${lectureId}/`;
  }

  async goto() {
    await this.page.goto(this.link);
  }

  async subscribe() {
    await this.goto();
    await this.page.getByRole("button", { name: "subscribe event series" }).click();
  }
}
