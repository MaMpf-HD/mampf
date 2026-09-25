import { expect, test } from "./_support/fixtures";
import { createReleasedLecture, subscribeToLecture } from "./user_registration/helpers";
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

    const markedRead = student.page.waitForResponse(
      response => response.url().includes("/notifications/"),
    );
    await news.getByRole("link", { name: "Mark as read" }).click();
    await markedRead;

    await expect(student.page.getByRole("region", { name: "New in this course" })).toHaveCount(0);
    await home.goto();
    await expect(student.page.getByText("The exercise class has moved to room 5."))
      .toHaveCount(0);
  });
});
