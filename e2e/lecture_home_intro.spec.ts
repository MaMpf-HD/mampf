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
    locale: "en",
  });

  const editPage = new LectureEditPage(teacher.page, lecture.id);
  await editPage.goto();
  await editPage.homeTab.click();

  // Build the content through Trix's own editor API rather than by simulated
  // keystrokes: typing "$$" and "\sum" with interleaved Enter presses races
  // with Trix's input handling and intermittently splits them across <br>s
  // (e.g. "$<br>$"), which is flaky. This is deterministic and still exercises
  // the real case — display math whose delimiters are broken across <br>s.
  const editor = teacher.page.getByTestId("lecture-home-intro-editor");
  await editor.evaluate((element) => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const trix = (element as any).editor;
    trix.insertString("Welcome, we study $x^2$");
    trix.insertLineBreak();
    trix.insertLineBreak();
    trix.insertString("$$");
    trix.insertLineBreak();
    trix.insertString("\\sum");
    trix.insertLineBreak();
    trix.insertString("$$");
  });

  // the preview mirrors the editor and KaTeX typesets both the inline and the
  // display formula — the client-side part a request spec cannot cover
  await expect(teacher.page.getByTestId("lecture-home-intro-preview"))
    .toContainText("Welcome, we study");
  await expect(teacher.page.getByTestId("lecture-home-intro-preview")
    .locator(".katex"))
    .toHaveCount(2);

  await teacher.page.getByTestId("lecture-home-save").click();
  await expect.poll(() => lecture.__call("home_intro_present?")).toBe(true);

  await new CampaignRegistrationPage(student.page, lecture.id).goto();
  await expect(student.page.getByTestId("lecture-home-intro"))
    .toContainText("Welcome, we study");
});
