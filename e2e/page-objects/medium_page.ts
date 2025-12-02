import { Page } from "../_support/fixtures";

export class MediumPage {
  readonly page: Page;
  readonly linkEdit: string;

  constructor(page: Page, mediumId: number) {
    this.page = page;
    this.linkEdit = `/media/${mediumId}/edit`;
  }

  async gotoEdit() {
    await this.page.goto(this.linkEdit);
  }
}
