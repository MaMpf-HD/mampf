import { expect, Locator, test } from "./_support/fixtures";
import { ThymePlayer } from "./page-objects/thyme_player";

/**
 * Spans two lines and carries markup that would run a script if it were
 * inserted as HTML; all of it has to come out as typed.
 */
const COMMENT
  = "Why is a<b here?\nSee <i>Lemma 2</i> and <img src=x onerror=\"window.xss = true\">.";

/**
 * `toHaveText` collapses whitespace, so the line break is read off `innerText`.
 * No image element may exist, since that is what would run the script.
 */
async function expectShownAsTyped(locator: Locator) {
  await expect(locator).toHaveJSProperty("innerText", COMMENT);
  await expect(locator.getByRole("img")).toHaveCount(0);
}

test.describe("annotation comments", () => {
  test("shows the teacher a shared comment as typed", async ({ factory, teacher, student }) => {
    const lecture = await factory.create("lecture_with_sparse_toc", [], {
      teacher_id: teacher.user.id,
    });
    const lesson = await factory.create("valid_lesson", [], { lecture_id: lecture.id });
    const medium = await factory.create("lesson_medium",
      ["with_video", "released", "with_lesson_by_id"], { lesson_id: lesson.id });
    await factory.create("annotation", ["shared_with_teacher"], {
      medium_id: medium.id, user_id: student.user.id, category: "mistake", comment: COMMENT,
    });

    const player = new ThymePlayer(teacher.page, medium.id);
    await player.gotoFeedback();
    await player.openAnnotationMarker(player.annotationMarkers.first());

    await expectShownAsTyped(player.annotationComment);
  });

  test("previews a comment as typed while writing it", async ({ factory, student: { page } }) => {
    const medium = await factory.create("lesson_medium", ["with_video", "released"]);
    const player = new ThymePlayer(page, medium.id);
    await player.goto();

    await player.annotationButton.click();
    await player.annotationDialog.getByRole("textbox").fill(COMMENT);

    await expectShownAsTyped(player.annotationPreview);
  });
});

test.describe("annotations visibility", () => {
  test("keeps an annotation shared before the teacher stopped sharing visible to the teacher",
    async ({ factory, teacher, student }) => {
      const lecture = await factory.create("lecture_with_sparse_toc", ["with_title"], {
        title: "Groundbreaking lecture", teacher_id: teacher.user.id,
      });
      const lesson = await factory.create("valid_lesson", [], { lecture_id: lecture.id });
      const medium = await factory.create("lesson_medium",
        ["with_video", "released", "with_lesson_by_id"],
        { lesson_id: lesson.id, description: "Soil medium" });
      const annotation = await factory.create("annotation", ["with_text", "shared_with_teacher"], {
        medium_id: medium.id, user_id: student.user.id,
        category: "mistake", comment: "The sign is wrong here.",
      });

      const page = teacher.page;
      await page.goto(`/lectures/${lecture.id}/edit?tab=communication`);
      await page.getByRole("radio", { name: "no", exact: true }).check();
      // The only Save on the tab: the mail to students has a Send of its own.
      const saved = page.waitForResponse(response =>
        response.request().method() === "POST" && response.url().endsWith(`/lectures/${lecture.id}`));
      await page.getByRole("button", { name: "Save", exact: true }).click();
      await saved;

      await page.reload();
      await expect(page.getByRole("radio", { name: "no", exact: true })).toBeChecked();
      await expect(page.getByRole("radio", { name: "yes", exact: true })).not.toBeChecked();

      const player = new ThymePlayer(page, medium.id);
      await player.gotoFeedback();
      await expect(player.annotationMarkers).toHaveCount(1);
      await player.openAnnotationMarker(player.annotationMarkers.first());

      await expect(player.annotationCategory).toContainText(annotation.category as string);
      await expect(player.annotationComment).toContainText(annotation.comment as string);
    });
});
