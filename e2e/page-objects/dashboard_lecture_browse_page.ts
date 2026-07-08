import { Page } from "../_support/fixtures";

export class DashboardLectureBrowsePage {
  readonly page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  async goto() {
    await this.page.goto("/");
  }

  async gotoWithTermScopeDeepLink(termScope: string) {
    const lectureSearchPromise = this.getLectureSearchPromise();
    await this.page.goto(`/?term_scope=${termScope}#lecture-search`);
    await lectureSearchPromise;
  }

  async scrollToSearchBar() {
    await this.page.getByTestId("lecture-search").scrollIntoViewIfNeeded();
  }

  async getLectureSearchPromise() {
    return this.page.waitForResponse(response =>
      response.url().includes("lectures/search"),
    );
  }

  async scrollToSearchAndWaitForResults() {
    const lectureSearchPromise = this.getLectureSearchPromise();
    await this.scrollToSearchBar();
    await lectureSearchPromise;
  }

  async searchFor(query: string) {
    const lectureSearchPromise = this.getLectureSearchPromise();
    await this.page.getByTestId("lecture-search-bar").fill(query);
    await lectureSearchPromise;
  }

  get currentTermFilter() {
    return this.page.getByLabel("Current term");
  }

  get nextTermFilter() {
    return this.page.getByLabel("Next term");
  }

  async selectCurrentTerm() {
    const lectureSearchPromise = this.getLectureSearchPromise();
    await this.page.getByText("Current term").click();
    await lectureSearchPromise;
  }

  async selectNextTerm() {
    const lectureSearchPromise = this.getLectureSearchPromise();
    await this.page.getByText("Next term").click();
    await lectureSearchPromise;
  }

  async clearNextTerm() {
    const lectureSearchPromise = this.getLectureSearchPromise();
    await this.page.getByText("Next term").click();
    await lectureSearchPromise;
  }

  async clearNextTermWithKeyboard() {
    const lectureSearchPromise = this.getLectureSearchPromise();
    await this.nextTermFilter.focus();
    await this.nextTermFilter.press("Space");
    await lectureSearchPromise;
  }

  async clearCurrentTerm() {
    const lectureSearchPromise = this.getLectureSearchPromise();
    await this.page.getByText("Current term").click();
    await lectureSearchPromise;
  }

  async clearCurrentTermWithKeyboard() {
    const lectureSearchPromise = this.getLectureSearchPromise();
    await this.currentTermFilter.focus();
    await this.currentTermFilter.press("Space");
    await lectureSearchPromise;
  }

  async scrollToBottom() {
    await this.page.evaluate(() => {
      window.scrollTo(0, document.body.scrollHeight);
    });
    // Hack such that scrolling itself is really finished before we continue
    await this.page.waitForTimeout(500);
  }

  get results() {
    return this.page.getByTestId("lecture-search-results");
  }

  get nextTermBanner() {
    return this.page.getByTestId("next-term-banner");
  }

  async clickNextTermBannerCta() {
    const lectureSearchPromise = this.getLectureSearchPromise();
    await this.page.getByTestId("next-term-banner-cta").click();
    await lectureSearchPromise;
  }

  async dismissNextTermBanner() {
    await this.page.getByTestId("next-term-banner-dismiss").click();
  }

  async getLectureCardCount() {
    const lectureCards = this.page.getByTestId("lecture-search-result-card");
    return await lectureCards.count();
  }
}
