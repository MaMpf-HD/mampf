import { Page } from "../_support/fixtures";

export class MediumCommentsPage {
  readonly page: Page;
  readonly link: string;

  constructor(page: Page, mediumId: number) {
    this.page = page;
    this.link = `/media/${mediumId}/show_comments`;
  }

  async goto() {
    await this.page.goto(this.link, { waitUntil: "domcontentloaded" });
  }

  async postComment(comment: string) {
    await this.page.getByRole("button", { name: "new comment" }).click();
    const textarea = this.page.getByTestId("comment-new-textarea");
    await textarea.waitFor({ state: "visible" });
    await textarea.fill(comment);
    await this.page.getByRole("button", { name: "post comment" }).click();
  }
}
