import { expect, test } from "./_support/fixtures";
import { ThymePlayer } from "./page-objects/thyme_player";

const REMARK_TEXT = "Test Remark";

test("opens content sidebar when TOC item exists, keeps it hidden otherwise",
  async ({ factory, student: { page } }) => {
    const lecture = await factory.create("lecture", ["released_for_all", "with_sparse_toc"]);
    const lesson = await factory.create("valid_lesson", [], { lecture_id: lecture.id });
    const mediumWithToc = await factory.create("lesson_medium",
      ["released", "with_lesson_by_id", "with_video", "with_toc_item"], { lesson_id: lesson.id });
    const mediumWithoutToc = await factory.create("lesson_medium",
      ["released", "with_lesson_by_id", "with_video"], { lesson_id: lesson.id });

    await new ThymePlayer(page, mediumWithToc.id).goto();
    const sidebar = page.getByTestId("thyme-content-sidebar");
    await expect(sidebar).toBeVisible();
    await expect(sidebar).toContainText(REMARK_TEXT);

    await new ThymePlayer(page, mediumWithoutToc.id).goto();
    const sidebar2 = page.getByTestId("thyme-content-sidebar");
    await expect(sidebar2).not.toBeVisible();
    await expect(sidebar2).not.toContainText(REMARK_TEXT);
  });
