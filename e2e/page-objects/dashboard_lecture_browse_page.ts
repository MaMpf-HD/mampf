import { Page } from "../_support/fixtures";

export class DashboardLectureBrowsePage {
  readonly page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  async goto() {
    await this.page.goto("/");
  }

  async gotoTerm(termSlug: string) {
    await this.page.goto(`/?term=${termSlug}`);
  }

  async gotoTermScopeDeepLink(termScope: string) {
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

  get termSelect() {
    return this.page.getByTestId("dashboard-term-select");
  }

  get searchTermSelect() {
    return this.page.getByTestId("lecture-search-term-select");
  }

  /**
   * Picks a semester in the dashboard's term dropdown, by its visible label.
   * This refreshes the term-dependent regions in place via Turbo Stream (no
   * navigation) and updates the URL to `/?term=<slug>`; we wait for the
   * `?term=` value to change.
   */
  async selectTerm(label: string) {
    const before = new URL(this.page.url()).searchParams.get("term");
    const urlUpdated = this.page.waitForURL(
      url => (url.searchParams.get("term") ?? null) !== before,
    );
    await this.termSelect.selectOption({ label });
    await urlUpdated;
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
    const termUrlPromise = this.page.waitForURL(url =>
      url.searchParams.has("term"),
    );

    await this.page.getByTestId("next-term-banner-cta").click();
    await Promise.all([lectureSearchPromise, termUrlPromise]);
  }

  async getLectureCardCount() {
    const lectureCards = this.page.getByTestId("lecture-search-result-card");
    return await lectureCards.count();
  }
}
