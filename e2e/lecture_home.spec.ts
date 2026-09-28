import { expect, test } from "./_support/fixtures";
import {
  createReleasedLecture,
  createTutorialItemsCampaign,
  subscribeToLecture,
} from "./user_registration/helpers";
import { CampaignRegistrationPage } from "./page-objects/campaign_registrations_page";

test.describe("lecture home", () => {
  test("says which sheet the student still has to hand in", async ({
    factory,
    student,
  }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    await factory.create("assignment", [], {
      lecture_id: lecture.id,
      title: "Sheet 3",
      deadline: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString(),
    });

    await new CampaignRegistrationPage(student.page, lecture.id).goto();

    const handIns = student.page.getByRole("region", { name: "Your hand-ins" });
    await expect(handIns).toContainText("Sheet 3");
    await expect(handIns).toContainText("Nothing handed in yet");
    await expect(handIns.getByRole("link", { name: "Go to your hand-in" })).toBeVisible();
  });

  test("shows the last session and takes new material off once seen", async ({
    factory,
    student,
  }) => {
    const lecture = await factory.create("lecture_with_sparse_toc",
      ["released_for_all", "term_independent"]);
    await subscribeToLecture(factory, lecture, student.user.id);
    const lesson = await factory.create("valid_lesson", [], {
      lecture_id: lecture.id,
      date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10),
    });
    const medium = await factory.create("lesson_medium",
      ["with_manuscript", "released", "with_lesson_by_id"],
      { lesson_id: lesson.id, description: "Sheet 5" });
    await factory.create("notification", [], {
      recipient_id: student.user.id,
      notifiable_type: "Medium",
      notifiable_id: medium.id,
    });

    await student.page.goto(`/lectures/${lecture.id}`);

    const content = student.page.getByRole("region", { name: "In the lecture" });
    await expect(content).toContainText("Last lecture");
    await expect(content).toContainText(await lesson.__call("section_titles"));
    await expect(content.getByRole("link", { name: "Notes" })).toBeVisible();
    await expect(content).toContainText("New for you");
    await expect(content.getByRole("link", { name: /Sheet 5/ })).toBeVisible();

    await content.getByRole("button", { name: "mark as seen" }).click();
    await expect(content).not.toContainText("New for you");

    await student.page.reload();
    await expect(student.page.getByRole("region", { name: "In the lecture" }))
      .not.toContainText("New for you");
  });

  test("marks the sidebar entry of a page opened from the review links", async ({
    factory,
    student,
  }) => {
    const lecture = await factory.create("lecture_with_sparse_toc",
      ["released_for_all", "term_independent"]);
    await subscribeToLecture(factory, lecture, student.user.id);
    const lesson = await factory.create("valid_lesson", [], {
      lecture_id: lecture.id,
      date: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10),
    });
    await factory.create("lesson_medium",
      ["with_manuscript", "released", "with_lesson_by_id"],
      { lesson_id: lesson.id });

    await student.page.goto(`/lectures/${lecture.id}`);
    const content = student.page.getByRole("region", { name: "In the lecture" });
    await expect(content).toContainText("For review");
    await content.getByRole("link", { name: "Lesson", exact: true }).click();

    const sidebar = student.page.getByRole("navigation")
      .filter({ has: student.page.getByRole("link", { name: "Lessons" }) });
    await expect(sidebar.getByRole("listitem")
      .filter({ has: student.page.getByRole("link", { name: "Lessons" }) }))
      .toHaveClass(/active-item/);
    await expect(sidebar.getByRole("listitem")
      .filter({ has: student.page.getByRole("link", { name: "Home" }) }))
      .not.toHaveClass(/active-item/);
  });

  test("takes an announcement off the page once it is read", async ({
    factory,
    student,
  }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    const announcement = await factory.create("announcement", [], {
      lecture_id: lecture.id,
      announcer_id: student.user.id,
      details: "The exercise class has moved to room 5.",
    });
    await factory.create("notification", [], {
      recipient_id: student.user.id,
      notifiable_type: "Announcement",
      notifiable_id: announcement.id,
    });

    const home = new CampaignRegistrationPage(student.page, lecture.id);
    await home.goto();

    const news = student.page.getByRole("region", { name: "New in this course" });
    await expect(news).toContainText("The exercise class has moved to room 5.");
    const badge = student.page.getByTitle("Unread announcements and forum topics");
    await expect(badge).toHaveText("1");

    const markedRead = student.page.waitForResponse(
      response => response.url().includes("/notifications/"),
    );
    await news.getByRole("link", { name: "Mark as read" }).click();
    await markedRead;

    await expect(student.page.getByRole("region", { name: "New in this course" })).toHaveCount(0);
    await expect(badge).toBeHidden();
    await home.goto();
    await expect(student.page.getByText("The exercise class has moved to room 5."))
      .toHaveCount(0);
  });

  test("keeps the link to older announcements after the shown ones are read", async ({
    factory,
    student,
  }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    for (const details of ["First", "Second", "Third", "Fourth"]) {
      const announcement = await factory.create("announcement", [], {
        lecture_id: lecture.id,
        announcer_id: student.user.id,
        details: `${details} announcement`,
      });
      await factory.create("notification", [], {
        recipient_id: student.user.id,
        notifiable_type: "Announcement",
        notifiable_id: announcement.id,
      });
    }

    await new CampaignRegistrationPage(student.page, lecture.id).goto();
    const news = student.page.getByRole("region", { name: "New in this course" });
    for (let index = 0; index < 3; index++) {
      const markedRead = student.page.waitForResponse(
        response => response.url().includes("/notifications/"),
      );
      await news.getByRole("link", { name: "Mark as read" }).first().click();
      await markedRead;
    }

    await expect(news.getByRole("link", { name: "1 more announcement" })).toBeVisible();
  });

  test("offers to try again when a campaign's options do not load", async ({
    factory,
    student,
  }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    await createTutorialItemsCampaign(factory, lecture, "first_come_first_served",
      "Tutorial registration");

    await student.page.route("**/home/campaigns/**", route => route.fulfill({ status: 404 }));
    const home = new CampaignRegistrationPage(student.page, lecture.id);
    await home.goto();
    const campaign = await home.openCampaign("Tutorial registration");

    await expect(campaign.getByText("The options could not be loaded.")).toBeVisible();

    await student.page.unroute("**/home/campaigns/**");
    await campaign.getByRole("button", { name: "Try again" }).click();

    await expect(home.registerButtons()).toHaveCount(3);
  });
});
