import { expect, test } from "./_support/fixtures";
import { createTutorialItemsCampaign, subscribeToLecture } from "./user_registration/helpers";
import { CampaignRegistrationPage } from "./page-objects/campaign_registrations_page";

// A registration process that is already open still takes new groups, until
// its allocation is computed; students see them at once.
test("adds a group to an open registration process", async ({ factory, teacher, student }) => {
  const course = await factory.create("course", [], { title: "Advanced Calculus" });
  const lecture = await factory.create("lecture", ["released_for_all"], {
    course_id: course.id, teacher_id: teacher.user.id,
  });
  await subscribeToLecture(factory, lecture, student.user.id);
  await createTutorialItemsCampaign(factory, lecture, "first_come_first_served", "Tutorial registration");

  const { page } = teacher;
  await page.goto(`/lectures/${lecture.id}/edit?tab=groups`);
  await page.getByRole("link", { name: "Add Tutorial" }).click();
  const dialog = page.getByRole("dialog");
  await dialog.getByRole("textbox", { name: "Title" }).fill("Late Tutorial");
  await dialog.getByRole("button", { name: /Create|Save/ }).click();
  await expect(dialog).toBeHidden();

  const home = new CampaignRegistrationPage(student.page, lecture.id);
  await home.goto();
  const fold = await home.openCampaign("Tutorial registration");
  await expect(fold.getByTestId("registration-option").filter({ hasText: "Late Tutorial" }))
    .toBeVisible();
});
