import { Page } from "../_support/fixtures";

export class DashboardLectureBrowsePage {
  readonly page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  async goto() {
    await this.page.goto("/");
  }

  async gotoWithSemesterDeepLink(semester: string) {
    const lectureSearchPromise = this.getLectureSearchPromise();
    await this.page.goto(`/?semester=${semester}#lecture-search`);
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

  get currentSemesterFilter() {
    return this.page.getByLabel("Current semester");
  }

  get nextSemesterFilter() {
    return this.page.getByLabel("Next semester");
  }

  async selectCurrentSemester() {
    const lectureSearchPromise = this.getLectureSearchPromise();
    await this.page.getByText("Current semester").click();
    await lectureSearchPromise;
  }

  async clearNextSemester() {
    const lectureSearchPromise = this.getLectureSearchPromise();
    await this.page.getByText("Next semester").click();
    await lectureSearchPromise;
  }

  async clearCurrentSemester() {
    const lectureSearchPromise = this.getLectureSearchPromise();
    await this.page.getByText("Current semester").click();
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

  get nextSemesterBanner() {
    return this.page.getByTestId("next-semester-banner");
  }

  async clickNextSemesterBannerCta() {
    const lectureSearchPromise = this.getLectureSearchPromise();
    await this.page.getByTestId("next-semester-banner-cta").click();
    await lectureSearchPromise;
  }

  async dismissNextSemesterBanner() {
    await this.page.getByTestId("next-semester-banner-dismiss").click();
  }

  async getLectureCardCount() {
    const lectureCards = this.page.getByTestId("lecture-search-result-card");
    return await lectureCards.count();
  }
}
