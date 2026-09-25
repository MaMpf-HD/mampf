import { Page, test, expect } from "../_support/fixtures";
import {
  createReleasedLecture,
  subscribeToLecture,
} from "./helpers";
import { CampaignRegistrationPage } from "../page-objects/campaign_registrations_page";

async function openSelfEnrollment(page: Page): Promise<void> {
  await page.getByRole("heading", { name: "Join a group yourself" }).click();
}

test.describe("student self-enrollment", () => {
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

    const home = new CampaignRegistrationPage(student.page, lecture.id);
    await home.goto();
    await openSelfEnrollment(student.page);

    await student.page.getByRole("button", { name: "Register for Self-managed Tutorial" })
      .click();

    await expect(home.participation("Self-managed Tutorial")).toContainText("Assigned");
    await expect(student.page.getByTestId("self-enrollment")).toHaveAttribute("open", "");
    await expect(student.page.getByTestId("self-enrollment").locator("summary")).toBeFocused();

    await home.participation("Self-managed Tutorial")
      .getByRole("button", { name: "Leave" }).click();

    await expect(home.participation("Self-managed Tutorial")).toHaveCount(0);
    await expect(student.page.getByTestId("self-enrollment").locator("summary")).toBeFocused();
    await expect(student.page.getByRole("button", {
      name: "Register for Self-managed Tutorial",
    })).toBeVisible();
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
    await openSelfEnrollment(student.page);

    const option = student.page.getByTestId("registration-option")
      .filter({ hasText: "Full Self-managed Tutorial" });
    await expect(option.getByText("No places left.")).toBeVisible();
    await expect(option.getByRole("button", { name: "Full" })).toBeDisabled();
    await expect(option.getByRole("button", { name: /^Register for / })).toHaveCount(0);
  });

  test("leaves out the registrations when no campaigns or free groups exist", async ({
    factory,
    student,
  }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);

    await new CampaignRegistrationPage(student.page, lecture.id).goto();

    await expect(student.page.getByRole("heading", { name: "Registrations" })).toHaveCount(0);
  });

  test("switches from one self-managed tutorial to another", async ({
    factory,
    student,
  }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    const current = await factory.create("tutorial", [], {
      lecture_id: lecture.id,
      title: "Monday Tutorial",
      skip_campaigns: true,
      self_materialization_mode: "add_and_remove",
    });
    await factory.create("tutorial_membership", [], {
      tutorial_id: current.id,
      user_id: student.user.id,
    });
    await factory.create("tutorial", [], {
      lecture_id: lecture.id,
      title: "Friday Tutorial",
      skip_campaigns: true,
      self_materialization_mode: "add_and_remove",
    });

    const home = new CampaignRegistrationPage(student.page, lecture.id);
    await home.goto();
    await openSelfEnrollment(student.page);
    await student.page.getByRole("button", { name: "Switch to Friday Tutorial" }).click();

    await expect(home.participation("Friday Tutorial")).toContainText("Assigned");
    await expect(home.participation("Monday Tutorial")).toHaveCount(0);
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
    await openSelfEnrollment(student.page);

    const option = (title: string) =>
      student.page.getByTestId("registration-option").filter({ hasText: title });

    await expect(option("Switchable Tutorial").getByRole("button", { name: "Unavailable" }))
      .toBeDisabled();
    await expect(option("Switchable Tutorial")
      .getByRole("button", { name: /^(Register|Switch) / })).toHaveCount(0);

    await expect(option("Deepening Group")
      .getByRole("button", { name: "Register for Deepening Group" })).toBeVisible();
  });
});
