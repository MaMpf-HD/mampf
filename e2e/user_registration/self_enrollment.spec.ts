import { test, expect } from "../_support/fixtures";
import { enableFeature } from "../_support/backend";
import {
  createReleasedLecture,
  subscribeToLecture,
} from "./helpers";
import { CampaignRegistrationPage } from "../page-objects/campaign_registrations_page";

test.describe("student self-enrollment", () => {
  test.beforeEach(async ({ request }) => {
    await enableFeature(request, "registration_campaigns");
    await enableFeature(request, "roster_maintenance");
  });

  test("adds and removes the student from a self-managed tutorial", async ({
    factory,
    student,
  }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    await factory.create("tutorial", [], {
      lecture_id: lecture.id,
      title: "Self-managed Tutorial",
      capacity: 2,
      skip_campaigns: true,
      self_materialization_mode: "add_and_remove",
    });

    await new CampaignRegistrationPage(student.page, lecture.id).goto();

    const tutorialTile = student.page.locator(".tutorial-gtile", {
      hasText: "Self-managed Tutorial",
    });
    await expect(tutorialTile.getByRole("button", { name: "Register now" })).toBeVisible();

    await tutorialTile.getByRole("button", { name: "Register now" }).click();

    const confirmedRegistrations = student.page.locator(".student-registration-rosterized-notice");
    await expect(confirmedRegistrations).toContainText("Your registration is confirmed for");
    await expect(confirmedRegistrations).toContainText("Self-managed Tutorial");
    await expect(tutorialTile.getByRole("button", { name: "Withdraw" })).toBeVisible();

    await tutorialTile.getByRole("button", { name: "Withdraw" }).click();

    await expect(student.page.getByText("Your registration is confirmed for")).toHaveCount(0);
    await expect(tutorialTile.getByRole("button", { name: "Register now" })).toBeVisible();
  });

  test("shows a full self-managed tutorial without an unsafe action", async ({
    factory,
    student,
    student2,
  }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    const tutorial = await factory.create("tutorial", [], {
      lecture_id: lecture.id,
      title: "Full Self-managed Tutorial",
      capacity: 1,
      skip_campaigns: true,
      self_materialization_mode: "add_and_remove",
    });
    await factory.create("tutorial_membership", [], {
      tutorial_id: tutorial.id,
      user_id: student2.user.id,
    });

    await new CampaignRegistrationPage(student.page, lecture.id).goto();

    const tutorialTile = student.page.locator(".tutorial-gtile", {
      hasText: "Full Self-managed Tutorial",
    });
    await expect(tutorialTile.getByText("1 / 1")).toBeVisible();
    await expect(tutorialTile.getByText("Full", { exact: true })).toBeVisible();
    await expect(tutorialTile.getByRole("button", { name: "Register now" })).toHaveCount(0);
  });

  test("renders the empty enrollment state when no campaigns or free groups exist", async ({
    factory,
    student,
  }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);

    await new CampaignRegistrationPage(student.page, lecture.id).goto();

    await expect(student.page.getByText(
      "There are currently no tutorials or groups available for registration.",
    )).toBeVisible();
  });

  test("blocks joining an exclusive tutorial while stuck in an unremovable "
    + "one, but keeps a coexisting cohort joinable", async ({ factory, student }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);

    const stuck = await factory.create("tutorial", [], {
      lecture_id: lecture.id,
      title: "Fixed Tutorial",
      skip_campaigns: true,
      self_materialization_mode: "add_only",
    });
    await factory.create("tutorial_membership", [], {
      tutorial_id: stuck.id,
      user_id: student.user.id,
    });

    await factory.create("tutorial", [], {
      lecture_id: lecture.id,
      title: "Switchable Tutorial",
      skip_campaigns: true,
      self_materialization_mode: "add_and_remove",
    });

    await factory.create("cohort", [], {
      context_id: lecture.id,
      context_type: "Lecture",
      title: "Deepening Group",
      skip_campaigns: true,
      self_materialization_mode: "add_only",
    });

    await new CampaignRegistrationPage(student.page, lecture.id).goto();

    const tile = (title: string) =>
      student.page.getByTestId("registration-group-tile").filter({ hasText: title });

    await expect(tile("Switchable Tutorial")
      .getByTestId("registration-blocked-action")).toBeVisible();
    await expect(tile("Switchable Tutorial")
      .getByRole("button", { name: "Register now" })).toHaveCount(0);

    await expect(tile("Deepening Group")
      .getByRole("button", { name: "Register now" })).toBeVisible();
  });
});
