import { expect, test } from "./_support/fixtures";
import { LectureEditPage } from "./page-objects/lecture_edit_page";
import { CampaignRegistrationPage } from "./page-objects/campaign_registrations_page";

/**
 * The intro's live preview and its rendering on the home page are client-side,
 * so a request spec cannot see them. This drives the whole flow: a teacher
 * writes the intro, the preview mirrors it, and a student lands on the home
 * page and reads it.
 */
test("teacher authors a home intro and a student sees it", async ({
  factory,
  teacher,
  student,
}) => {
  const lecture = await factory.create("lecture", ["released_for_all"], {
    teacher_id: teacher.user.id,
  });

  const editPage = new LectureEditPage(teacher.page, lecture.id);
  await editPage.goto();
  await editPage.homeTab.click();

  await teacher.page.locator("#lecture-home-intro-trix").click();
  await teacher.page.keyboard.type("Welcome, we study $x^2$");

  // the preview updates from the editor as you type — the part a request spec
  // cannot cover (whether KaTeX then typesets the math is KaTeX's own concern)
  await expect(teacher.page.getByTestId("lecture-home-intro-preview"))
    .toContainText("Welcome, we study");

  await teacher.page.locator("#lecture-home-form")
    .getByRole("button", { name: "Save" }).click();
  await expect.poll(() => lecture.__call("home_intro_present?")).toBe(true);

  await new CampaignRegistrationPage(student.page, lecture.id).goto();
  await expect(student.page.getByTestId("lecture-home-intro"))
    .toContainText("Welcome, we study");
});
