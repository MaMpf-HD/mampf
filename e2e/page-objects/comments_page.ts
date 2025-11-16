import { Page } from "../_support/fixtures";

export class MediumCommentsPage {
  readonly page: Page;
  readonly link: string;

  constructor(page: Page, id: number) {
    this.page = page;
    this.link = `/media/${id}/show_comments`;
  }

  async goto() {
    await this.page.goto(this.link);
  }

  async postComment(comment: string) {
    await this.page.getByRole("button", { name: "new comment" }).click();
    await this.page.getByRole("textbox").fill(comment);
    await this.page.getByRole("button", { name: "post comment" }).click();
  }
}
