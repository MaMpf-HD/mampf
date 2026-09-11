import { expect, test } from "./_support/fixtures";
import { FactoryBot, FactoryBotObject } from "./_support/factorybot";
import { DashboardLectureBrowsePage } from "./page-objects/dashboard_lecture_browse_page";

function createActiveTerm(factory: FactoryBot) {
  return factory.create("term", ["summer", "active"], { year: 2025 });
}

test("bookmarks a lecture from the search results and removes it again from the board",
  async ({ factory, student: { page } }) => {
    const term = await createActiveTerm(factory);
    const course = await factory.create("course", [], { title: "Measure Theory" });
    const lecture = await factory.create("lecture", ["released_for_all"], {
      course_id: course.id,
      term_id: term.id,
    });

    const dashboard = new DashboardLectureBrowsePage(page);
    await dashboard.goto();
    await expect(dashboard.bookmarkedSection).not.toBeVisible();

    await dashboard.scrollToSearchAndWaitForResults();
    await dashboard.waitForBoardRefresh(async () => {
      await dashboard.searchResultBookmarkButton(lecture.id).click();
    });

    await expect(dashboard.bookmarkedSection).toContainText("Measure Theory");
    await expect(dashboard.searchResultBookmarkButton(lecture.id))
      .toHaveAttribute("aria-pressed", "true");

    await dashboard.removeBookmark(lecture.id);

    await expect(dashboard.bookmarkedSection).not.toBeVisible();
    await expect(dashboard.searchResultBookmarkButton(lecture.id))
      .toHaveAttribute("aria-pressed", "false");
  });

test("picks a washi tape colour for a card and keeps it across a reload",
  async ({ factory, student: { page, user } }) => {
    const term = await createActiveTerm(factory);
    const course = await factory.create("course", [], { title: "Functional Analysis" });
    const lecture = await factory.create("lecture", ["released_for_all"], {
      course_id: course.id,
      term_id: term.id,
    });
    await factory.create("lecture_user_join", [], {
      lecture_id: lecture.id,
      user_id: user.id,
    });

    const dashboard = new DashboardLectureBrowsePage(page);
    await dashboard.goto();

    const card = dashboard.dashboardCard(lecture.id);
    await expect(card).toBeVisible();
    await dashboard.chooseWashiTapeColor(lecture.id, "Mint");
    await expect(card).toHaveAttribute("style", /--washi-tape-color-mint/);

    await page.reload();
    await expect(dashboard.dashboardCard(lecture.id))
      .toHaveAttribute("style", /--washi-tape-color-mint/);
    await dashboard.openWashiTapePicker(lecture.id);
    await expect(dashboard.dashboardCard(lecture.id)
      .getByRole("radio", { name: "Mint" })).toBeChecked();
  });

test.describe("a rejected registration's notice", () => {
  async function createLectureWithRejectedRegistration(
    factory: FactoryBot, userId: number,
  ): Promise<FactoryBotObject> {
    const term = await createActiveTerm(factory);
    const course = await factory.create("course", [], { title: "Discrete Optimization" });
    const lecture = await factory.create("lecture", ["released_for_all"], {
      course_id: course.id,
      term_id: term.id,
    });
    // closed, not open: an open campaign's rejected application is still
    // reported as :open (re-registering is possible), not :rejected - see
    // Registration::StatusQuery#statuses
    const campaign = await factory.create("registration_campaign", ["closed"], {
      campaignable_type: "Lecture",
      campaignable_id: lecture.id,
    });
    const items = await campaign.__call("registration_items");
    await factory.create("registration_user_registration", ["rejected"], {
      user_id: userId,
      registration_campaign_id: campaign.id,
      registration_item_id: items[0].id,
    });

    return lecture;
  }

  test("can be dismissed while keeping the lecture bookmarked",
    async ({ factory, student: { page, user } }) => {
      const lecture = await createLectureWithRejectedRegistration(factory, user.id);

      const dashboard = new DashboardLectureBrowsePage(page);
      await dashboard.goto();

      await expect(dashboard.enrolledSection).toContainText("Discrete Optimization");
      await dashboard.dismissRegistrationNotice(lecture.id, true);

      // the lecture was the only enrolled one, so the band disappears (it is
      // not rendered at all once empty) rather than staying around empty
      await expect(dashboard.enrolledSection).not.toBeVisible();
      await expect(dashboard.bookmarkedSection).toContainText("Discrete Optimization");
    });

  test("can be dismissed while dropping the lecture entirely",
    async ({ factory, student: { page, user } }) => {
      const lecture = await createLectureWithRejectedRegistration(factory, user.id);

      const dashboard = new DashboardLectureBrowsePage(page);
      await dashboard.goto();

      await expect(dashboard.enrolledSection).toContainText("Discrete Optimization");
      await dashboard.dismissRegistrationNotice(lecture.id, false);

      await expect(dashboard.enrolledSection).not.toBeVisible();
      await expect(dashboard.bookmarkedSection).not.toBeVisible();
    });
});

test("remembers a folded dashboard section across a reload",
  async ({ factory, student: { page, user } }) => {
    const term = await createActiveTerm(factory);
    const course = await factory.create("course", [], { title: "Number Theory" });
    const lecture = await factory.create("lecture", ["released_for_all"], {
      course_id: course.id,
      term_id: term.id,
    });
    await factory.create("lecture_user_join", [], {
      lecture_id: lecture.id,
      user_id: user.id,
    });

    const dashboard = new DashboardLectureBrowsePage(page);
    await dashboard.goto();

    const toggle = dashboard.sectionToggle(
      "dashboard-bookmarked-lectures", "You bookmarked these",
    );
    const cards = dashboard.bookmarkedSection.getByTestId("lecture-dashboard-card");

    await expect(cards.first()).toBeVisible();
    await toggle.click();
    await expect(toggle).toHaveAttribute("aria-expanded", "false");
    await expect(cards.first()).toBeHidden();

    await page.reload();
    await expect(dashboard.sectionToggle(
      "dashboard-bookmarked-lectures", "You bookmarked these",
    )).toHaveAttribute("aria-expanded", "false");
    await expect(dashboard.bookmarkedSection
      .getByTestId("lecture-dashboard-card").first()).toBeHidden();
  });
