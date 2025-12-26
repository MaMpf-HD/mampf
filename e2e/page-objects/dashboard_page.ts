import { Page } from "../_support/fixtures";

export class DashboardPage {
  readonly page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  async goto() {
    await this.page.goto("/");
  }

  async scrollToSearchBar() {
    await this.page.locator("#lecture-search").scrollIntoViewIfNeeded();
  }

  async waitForInitialResults() {
    const lectureSearchPromise = this.page.waitForResponse(response =>
      response.url().includes("lectures/search"),
    );
    await this.scrollToSearchBar();
    await lectureSearchPromise;
  }

  async searchFor(query: string) {
    await this.page.locator("#lecture-search-bar").fill(query);
    await this.page.waitForTimeout(400);
  }

  async scrollToBottom() {
    await this.page.evaluate(() => {
      window.scrollTo(0, document.body.scrollHeight);
    });
    await this.page.waitForTimeout(500);
  }

  get results() {
    return this.page.locator("#lecture-search-results");
  }

  get lectureCards() {
    return this.page.locator("#lecture-search-results .lecture-card");
  }

  async getLectureCardCount() {
    return await this.lectureCards.count();
  }
}
