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

test("removes a bookmark after navigating to the lecture and back",
  async ({ factory, student: { page, user } }) => {
    const term = await createActiveTerm(factory);
    const course = await factory.create("course", [], { title: "Measure Theory" });
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

    // regression test: RemovalModalController parks the removal-confirmation
    // dialog in <body>.  Turbo Drive's page cache used to lose track of it
    // across a back-navigation, breaking the "x" button on a restored dashboard.
    await dashboard.openLectureAndGoBack(lecture.id);

    await dashboard.removeBookmark(lecture.id);
    await expect(dashboard.bookmarkedSection).not.toBeVisible();
  });

test("picks a washi tape color for a card and keeps it across a reload",
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

test("picks a washi tape color for a card shown only through a pending registration",
  async ({ factory, student: { page, user } }) => {
    const term = await createActiveTerm(factory);
    const course = await factory.create("course", [], { title: "Topological Groups" });
    const lecture = await factory.create("lecture", ["released_for_all"], {
      course_id: course.id,
      term_id: term.id,
    });
    const campaign = await factory.create("registration_campaign", ["open"], {
      campaignable_type: "Lecture",
      campaignable_id: lecture.id,
    });
    const items = await campaign.__call("registration_items");
    await factory.create("registration_user_registration", ["pending"], {
      user_id: user.id,
      registration_campaign_id: campaign.id,
      registration_item_id: items[0].id,
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
  });

test.describe("registration status with multiple campaigns for one lecture", () => {
  async function createLecture(factory: FactoryBot, title: string) {
    const term = await createActiveTerm(factory);
    const course = await factory.create("course", [], { title });
    return factory.create("lecture", ["released_for_all"], {
      course_id: course.id,
      term_id: term.id,
    });
  }

  async function createRegistration(
    factory: FactoryBot,
    lecture: FactoryBotObject,
    userId: number,
    campaignTrait: "open" | "closed",
    registrationStatus: "confirmed" | "pending" | "rejected",
  ) {
    const campaign = await factory.create("registration_campaign", [campaignTrait], {
      campaignable_type: "Lecture",
      campaignable_id: lecture.id,
    });
    const items = await campaign.__call("registration_items");
    await factory.create("registration_user_registration", [registrationStatus], {
      user_id: userId,
      registration_campaign_id: campaign.id,
      registration_item_id: items[0].id,
    });
    return campaign;
  }

  async function createOpenCampaignWithoutRegistration(
    factory: FactoryBot, lecture: FactoryBotObject,
  ) {
    return factory.create("registration_campaign", ["open"], {
      campaignable_type: "Lecture",
      campaignable_id: lecture.id,
    });
  }

  test("a confirmed registration wins over a rejected one in another campaign",
    async ({ factory, student: { page, user } }) => {
      const lecture = await createLecture(factory, "Algebraic Topology");
      await createRegistration(factory, lecture, user.id, "closed", "rejected");
      await createRegistration(factory, lecture, user.id, "closed", "confirmed");

      const dashboard = new DashboardLectureBrowsePage(page);
      await dashboard.goto();

      // confirmed is the default state and shows no status note/corner at all
      await expect(dashboard.enrolledSection).toContainText("Algebraic Topology");
      const card = dashboard.dashboardCard(lecture.id);
      await expect(card.getByText("Rejected")).not.toBeVisible();
      await expect(card.getByText("Pending")).not.toBeVisible();
      await expect(card.getByRole("button", { name: "Dismiss" })).not.toBeVisible();
    });

  test("a confirmed registration wins over a pending one in another campaign",
    async ({ factory, student: { page, user } }) => {
      const lecture = await createLecture(factory, "Complex Analysis");
      await createRegistration(factory, lecture, user.id, "open", "pending");
      await createRegistration(factory, lecture, user.id, "closed", "confirmed");

      const dashboard = new DashboardLectureBrowsePage(page);
      await dashboard.goto();

      const card = dashboard.dashboardCard(lecture.id);
      await expect(card.getByText("Pending")).not.toBeVisible();
    });

  test("a pending registration wins over a rejected one in another campaign",
    async ({ factory, student: { page, user } }) => {
      const lecture = await createLecture(factory, "Differential Geometry");
      await createRegistration(factory, lecture, user.id, "closed", "rejected");
      await createRegistration(factory, lecture, user.id, "open", "pending");

      const dashboard = new DashboardLectureBrowsePage(page);
      await dashboard.goto();

      const card = dashboard.dashboardCard(lecture.id);
      await expect(card.getByText("Pending")).toBeVisible();
      await expect(card.getByText("Rejected")).not.toBeVisible();
      // the rejected notice's dismiss corner is only shown for :rejected
      await expect(card.getByRole("button", { name: "Dismiss" })).not.toBeVisible();
    });

  test("a still-open campaign wins over a rejected registration in a closed one",
    async ({ factory, student: { page, user } }) => {
      const lecture = await createLecture(factory, "Number Theory II");
      await createRegistration(factory, lecture, user.id, "closed", "rejected");
      await createOpenCampaignWithoutRegistration(factory, lecture);

      const dashboard = new DashboardLectureBrowsePage(page);
      await dashboard.goto();

      const card = dashboard.dashboardCard(lecture.id);
      await expect(card.getByText("Registration open")).toBeVisible();
      await expect(card.getByText("Rejected")).not.toBeVisible();
    });

  test("rejected registrations in two different closed campaigns are both cleared by one dismiss",
    async ({ factory, student: { page, user } }) => {
      const lecture = await createLecture(factory, "Topology");
      await createRegistration(factory, lecture, user.id, "closed", "rejected");
      await createRegistration(factory, lecture, user.id, "closed", "rejected");

      const dashboard = new DashboardLectureBrowsePage(page);
      await dashboard.goto();

      const card = dashboard.dashboardCard(lecture.id);
      await expect(card.getByText("Rejected")).toBeVisible();

      await dashboard.dismissRegistrationNotice(lecture.id, true);

      await expect(dashboard.bookmarkedSection).toContainText("Topology");
      await expect(dashboard.dashboardCard(lecture.id).getByText("Rejected"))
        .not.toBeVisible();
    });
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

  test("can still be dismissed after navigating to the lecture and back",
    async ({ factory, student: { page, user } }) => {
      const lecture = await createLectureWithRejectedRegistration(factory, user.id);

      const dashboard = new DashboardLectureBrowsePage(page);
      await dashboard.goto();

      // regression test: RemovalModalController parks the removal-confirmation
      // dialog in <body> (see the comment there for why) - Turbo Drive's page
      // cache used to lose track of it across a back-navigation, silently
      // breaking the "x" button on a restored dashboard
      await dashboard.openLectureAndGoBack(lecture.id);

      await expect(dashboard.enrolledSection).toContainText("Discrete Optimization");
      await dashboard.dismissRegistrationNotice(lecture.id, true);

      await expect(dashboard.enrolledSection).not.toBeVisible();
      await expect(dashboard.bookmarkedSection).toContainText("Discrete Optimization");
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
