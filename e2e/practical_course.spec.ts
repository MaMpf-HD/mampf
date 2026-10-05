import { test, expect } from "./_support/fixtures";
import { subscribeToLecture } from "./user_registration/helpers";
import { CampaignRegistrationPage } from "./page-objects/campaign_registrations_page";

test("creates a practical course from the course page", async ({
  factory,
  teacher: { page, user },
}) => {
  const course = await factory.create("course", ["with_editor_by_id"],
    { editor_id: user.id, title: "Software Lab" });
  await factory.create("term");

  await page.goto(`/courses/${course.id}/edit`);
  const form = page.waitForResponse(
    response => response.url().includes("/lectures/new") && response.status() === 200,
  );
  await page.getByTestId("new-lecture-button-course-edit").click();
  await form;
  await page.getByLabel("Type").selectOption({ label: "Practical Course" });
  await page.getByTestId("new-lecture-submit").click();

  const alert = page.getByRole("alert");
  await expect(alert).toContainText("successfully");
  await expect(alert).toContainText("(P) Software Lab");
});

test("lets a student register for a practical course and join a team", async ({
  factory,
  student,
}) => {
  const course = await factory.create("course", [], { title: "Software Lab" });
  const lecture = await factory.create("lecture", ["released_for_all"],
    { course_id: course.id, sort: "practical" });
  await subscribeToLecture(factory, lecture, student.user.id);
  await factory.create("registration_campaign", ["open", "first_come_first_served"], {
    campaignable_type: "Lecture",
    campaignable_id: lecture.id,
    description: "Places in the lab",
    for_cohorts: true,
    items_count: 1,
  });
  await factory.create("cohort", [], {
    context_id: lecture.id,
    context_type: "Lecture",
    title: "Team 1",
    capacity: 3,
    skip_campaigns: true,
    self_materialization_mode: "add_and_remove",
  });

  const home = new CampaignRegistrationPage(student.page, lecture.id);
  await home.goto();
  await expect(student.page.getByTestId("lecture-home")).toContainText("Practical Course");

  await home.register(await home.openCampaign("Places in the lab"));
  await expect(student.page.getByText("Registration completed successfully.")).toBeVisible();

  await student.page.getByRole("heading", { name: "Join a group yourself" }).click();
  await student.page.getByRole("button", { name: "Register for Team 1" }).click();
  await expect(home.participation("Team 1")).toContainText("Assigned");
});
