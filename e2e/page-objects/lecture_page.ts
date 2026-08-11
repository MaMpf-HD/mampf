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

  async gotoManuscript() {
    await this.page.goto(`${this.link}/script`);
  }

  async subscribe() {
    await this.goto();
    const subscribeButton = this.page.getByRole("button", { name: "subscribe lecture" });
    await subscribeButton.click();
    await expect(subscribeButton).toHaveCount(0);
  }

  async addMediaToWatchlist(mediumID: number, watchlistName: string, submit = true) {
    await this.page.locator(`a[href="/watchlists/add_medium/${mediumID}"]`).click();
    // the select arrives with the frame, so waiting for it is the whole wait
    await this.page.locator("#watchlistSelect").selectOption({ label: watchlistName });
    if (submit) {
      await this.page.getByRole("button", { name: "Add to my watchlist" }).click();
    }
    else {
      await this.page.getByText("Close").click();
    }
  }
}
