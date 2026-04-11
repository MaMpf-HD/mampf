import { Page } from "../_support/fixtures";

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
    await this.page.getByRole("button", { name: "subscribe event series" }).click();
  }

  async addMediaToWatchlist(mediumID: number, watchlistName: string, submit = true) {
    await this.page.locator(`a[href="/watchlists/add_medium/${mediumID}"]`).hover();
    await this.page.waitForResponse(response => response.url().includes(`/watchlists/add_medium/${mediumID}`));
    await this.page.locator(`a[href="/watchlists/add_medium/${mediumID}"]`).click();
    await this.page.locator("#watchlistSelect").selectOption(watchlistName);
    if (submit) {
      await this.page.getByRole("button", { name: "Add to my watchlist" }).click();
    }
    else {
      await this.page.getByText("Close").click();
    }
  }
}
