import { test, expect } from "../_support/fixtures";
import { enableFeature } from "../_support/backend";
import {
  createReleasedLecture,
  createTutorialItemsCampaign,
  subscribeToLecture,
} from "./helpers";
import { CampaignRegistrationPage } from "../page-objects/campaign_registrations_page";

test.describe("campaign registration", () => {
  test.beforeEach(async ({ request }) => {
    await enableFeature(request, "registration_campaigns");
    await enableFeature(request, "roster_maintenance");
  });

  test("can be opened from the lecture enrollment tab", async ({ factory, student }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    await createTutorialItemsCampaign(
      factory,
      lecture,
      "first_come_first_served",
      "Tutorial registration",
    );

    await student.page.goto(`/lectures/${lecture.id}`);
    await student.page.getByRole("link", { name: "Enrollment" }).click();

    await expect(student.page.getByText("Tutorial registration")).toBeVisible();
    await expect(student.page.getByText("Register for a group.")).toBeVisible();
    await expect(student.page.getByRole("button", { name: "Register now" })).toHaveCount(3);
  });

  test("confirms and withdraws a first-come-first-served registration", async ({
    factory,
    student,
  }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    await createTutorialItemsCampaign(
      factory,
      lecture,
      "first_come_first_served",
      "Tutorial registration",
    );

    await new CampaignRegistrationPage(student.page, lecture.id).goto();

    const firstTile = student.page.locator(".tutorial-gtile").first();
    await firstTile.getByRole("button", { name: "Register now" }).click();

    await expect(student.page.getByText("Registration completed successfully.")).toBeVisible();
    await expect(student.page.getByRole("button", { name: "Withdraw" })).toHaveCount(1);
    await expect(student.page.getByText("Withdraw first")).toHaveCount(2);

    await student.page.getByRole("button", { name: "Withdraw" }).click();

    await expect(student.page.getByText("You have withdrawn your registration.")).toBeVisible();
    await expect(student.page.getByRole("button", { name: "Register now" })).toHaveCount(3);
  });

  test("keeps closed campaigns visible but read-only", async ({ factory, student }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    await createTutorialItemsCampaign(
      factory,
      lecture,
      "first_come_first_served",
      "Closed tutorial registration",
      "closed",
    );

    await new CampaignRegistrationPage(student.page, lecture.id).goto();

    await expect(student.page.getByText("Closed tutorial registration")).toBeVisible();
    await expect(student.page.getByText("Registration closed")).toBeVisible();
    await expect(student.page.getByRole("button", { name: "Register now" })).toHaveCount(3);

    const buttons = student.page.getByRole("button", { name: "Register now" });
    await expect(buttons.nth(0)).toBeDisabled();
    await expect(buttons.nth(1)).toBeDisabled();
    await expect(buttons.nth(2)).toBeDisabled();
  });

  test("stores preference ranks immediately and keeps ranks unique", async ({
    factory,
    student,
  }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    await createTutorialItemsCampaign(
      factory,
      lecture,
      "preference_based",
      "Preference tutorial registration",
    );

    await new CampaignRegistrationPage(student.page, lecture.id).goto();

    const firstTile = student.page.locator(".tutorial-gtile").nth(0);
    const secondTile = student.page.locator(".tutorial-gtile").nth(1);

    await firstTile.getByRole("button", { name: "1st" }).click();
    await expect(student.page.getByText("Your preferences have been saved.")).toBeVisible();
    await expect(firstTile.getByRole("button", { name: "1st" })).toHaveClass(/btn-primary/);

    await secondTile.getByRole("button", { name: "1st" }).click();

    await expect(secondTile.getByRole("button", { name: "1st" })).toHaveClass(/btn-primary/);
    await expect(firstTile.getByRole("button", { name: "2nd" })).toHaveClass(/btn-primary/);
    await expect(student.page.locator(".student-registration-rank-button.btn-primary"))
      .toHaveCount(2);
  });

  test("shows completed materialized assignments above remaining options", async ({
    factory,
    student,
  }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    const tutorial = await factory.create("tutorial", [], {
      lecture_id: lecture.id,
      title: "Assigned Tutorial",
      capacity: 2,
    });
    await factory.create("tutorial_membership", [], {
      tutorial_id: tutorial.id,
      user_id: student.user.id,
    });
    await createTutorialItemsCampaign(
      factory,
      lecture,
      "first_come_first_served",
      "Late tutorial registration",
    );

    await new CampaignRegistrationPage(student.page, lecture.id).goto();

    await expect(student.page.getByText("Your registration is confirmed for")).toBeVisible();
    await expect(student.page.getByText("Assigned Tutorial")).toBeVisible();
    await expect(student.page.getByText("Late tutorial registration")).toBeVisible();
  });
});
