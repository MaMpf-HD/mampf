import { Page } from "../_support/fixtures";

export class MediumCommentsPage {
  readonly page: Page;
  readonly link: string;

  constructor(page: Page, mediumId: number) {
    this.page = page;
    this.link = `/media/${mediumId}/show_comments`;
  }

  async goto() {
    await this.page.goto(this.link);
  }

  async postComment(comment: string) {
    const newCommentPromise = this.page.waitForResponse(response =>
      response.url().includes("comments/new"),
    );
    await this.page.getByRole("button", { name: "new comment" }).click();
    await newCommentPromise;

    const textarea = this.page.getByTestId("comment-new-textarea");
    await textarea.waitFor({ state: "visible" });
    await textarea.fill(comment);

    // The form posts by XHR; a reload right after the click would cancel it.
    const postedPromise = this.page.waitForResponse(response =>
      response.url().includes("/comments") && response.request().method() === "POST",
    );
    await this.page.getByRole("button", { name: "post comment" }).click();
    await postedPromise;
  }
}
