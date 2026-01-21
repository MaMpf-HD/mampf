import { Page } from "../_support/fixtures";

export class TalkPage {
  readonly page: Page;
  readonly link: string;

  constructor(page: Page, talkId: number) {
    this.page = page;
    this.link = `/talks/${talkId}`;
  }

  async goto() {
    await this.page.goto(this.link);
  }
}
