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

  /** Hrefs of all currently rendered lecture cards, in DOM order (duplicates kept). */
  async getLectureCardHrefs() {
    return await this.page.getByTestId("lecture-search-result-card")
      .evaluateAll(links => links.map(link => (link as HTMLAnchorElement).href));
  }

  get enrolledSection() {
    return this.page.getByTestId("dashboard-enrolled-lectures");
  }

  get bookmarkedSection() {
    return this.page.getByTestId("dashboard-bookmarked-lectures");
  }

  dashboardCard(lectureId: number) {
    return this.page.getByTestId("lecture-dashboard-card")
      .and(this.page.locator(`[data-lecture-id="${lectureId}"]`));
  }

  searchResultBookmarkButton(lectureId: number) {
    return this.page.locator(`[data-bookmark-lecture-id-value="${lectureId}"]`)
      .getByTestId("lecture-search-bookmark-button");
  }

  async openLectureAndGoBack(lectureId: number) {
    await this.dashboardCard(lectureId).click();
    await this.page.waitForURL(/\/lectures\//);
    await this.page.goBack();
    await this.page.waitForURL("/");
  }

  async waitForBoardRefresh(action: () => Promise<void>) {
    const refreshed = this.page.waitForResponse(response =>
      response.url().includes("/dashboard/") && response.status() === 200,
    );
    await action();
    await refreshed;
  }

  /** Removes a bookmarked lecture from the dashboard, confirming the modal. */
  async removeBookmark(lectureId: number) {
    const card = this.dashboardCard(lectureId);
    await this.waitForBoardRefresh(async () => {
      await card.getByRole("button", { name: "Remove bookmark" }).click();
      await this.page.getByRole("button", { name: "Remove", exact: true }).click();
    });
  }

  /** Dismisses a rejected registration's notice, either bookmarking or dropping the lecture. */
  async dismissRegistrationNotice(lectureId: number, keepBookmarked: boolean) {
    const card = this.dashboardCard(lectureId);
    const buttonName = keepBookmarked
      ? "Keep in bookmarked lectures"
      : "Remove entirely";

    await this.waitForBoardRefresh(async () => {
      await card.getByRole("button", { name: "Dismiss" }).click();
      await this.page.getByRole("button", { name: buttonName }).click();
    });
  }

  async openWashiTapePicker(lectureId: number) {
    await this.dashboardCard(lectureId).getByTestId("washi-tape-strip").click();
  }

  async chooseWashiTapeColor(lectureId: number, colorLabel: string) {
    await this.openWashiTapePicker(lectureId);
    await this.dashboardCard(lectureId)
      .getByRole("radio", { name: colorLabel }).click();
  }

  sectionToggle(sectionTestid: string, title: string) {
    return this.page.getByTestId(sectionTestid).getByRole("button", { name: title });
  }
}
