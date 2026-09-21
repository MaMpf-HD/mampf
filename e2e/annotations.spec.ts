import { expect, test } from "./_support/fixtures";
import { ThymePlayer } from "./page-objects/thyme_player";

test.describe("annotations visibility", () => {
  test("keeps an annotation shared before the teacher stopped sharing visible to the teacher",
    async ({ factory, teacher, student }) => {
      const lecture = await factory.create("lecture_with_sparse_toc", ["with_title"], {
        title: "Groundbreaking lecture", teacher_id: teacher.user.id, locale: "en",
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
      // The mail to students sits on the same tab with a submit of its own,
      // so the button is the one that appears next to the changed setting.
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
