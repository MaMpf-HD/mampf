import { Page } from "../_support/fixtures";

export class TutorialsPage {
  readonly page: Page;
  readonly link: string;

  constructor(page: Page, lectureId: number) {
    this.page = page;
    this.link = `/lectures/${lectureId}/tutorials`;
  }

  async goto() {
    await this.page.goto(this.link);
  }
}
