import { expect, test } from "./_support/fixtures";
import { FactoryBot, FactoryBotObject } from "./_support/factorybot";

/** Turbo fetches a link ahead once the pointer has rested on it this long. */
const PREFETCH_DELAY_MS = 100;

/**
 * Case-sensitive on purpose: looked up by its plain name, "Lock Board" would
 * also find "Unlock Board".
 */
const LOCK_BOARD = /Lock Board/;

async function lectureWithMedium(factory: FactoryBot, teacherId: number):
Promise<FactoryBotObject> {
  const lecture = await factory.create("lecture_with_sparse_toc", [], {
    teacher_id: teacherId,
  });
  const lesson = await factory.create("valid_lesson", [], { lecture_id: lecture.id });
  await factory.create("lesson_medium", ["with_video", "released", "with_lesson_by_id"],
    { lesson_id: lesson.id });
  return lecture;
}

test.describe("board and discussion switches of a lecture", () => {
  test("creates, locks, unlocks and deletes the board", async ({ factory, teacher }) => {
    const lecture = await lectureWithMedium(factory, teacher.user.id);
    const page = teacher.page;
    await page.goto(`/lectures/${lecture.id}/edit?tab=communication`);

    await page.getByRole("button", { name: "Create Board" }).click();
    await page.getByRole("button", { name: LOCK_BOARD }).click();
    await page.getByRole("button", { name: "Unlock Board" }).click();
    await expect(page.getByRole("button", { name: LOCK_BOARD })).toBeVisible();

    page.once("dialog", dialog => dialog.dismiss());
    await page.getByRole("button", { name: "Delete Board" }).click();
    await page.reload();
    await expect(page.getByRole("button", { name: "Delete Board" })).toBeVisible();

    page.once("dialog", dialog => dialog.accept());
    await page.getByRole("button", { name: "Delete Board" }).click();
    await expect(page.getByRole("button", { name: "Create Board" })).toBeVisible();
  });

  test("closes and reopens the discussions", async ({ factory, teacher }) => {
    const lecture = await lectureWithMedium(factory, teacher.user.id);
    const page = teacher.page;
    await page.goto(`/lectures/${lecture.id}/edit?tab=communication`);

    await page.getByRole("button", { name: "Close discussions for all related media" }).click();
    await page.getByRole("button", { name: "Reopen all closed discussions" }).click();
    await expect(page.getByRole("button", { name: "Close discussions for all related media" }))
      .toBeVisible();
  });

  test("leaves the board as it is while the pointer only rests on a switch",
    async ({ factory, teacher }) => {
      const lecture = await lectureWithMedium(factory, teacher.user.id);
      const page = teacher.page;
      await page.goto(`/lectures/${lecture.id}/edit?tab=communication`);
      await page.getByRole("button", { name: "Create Board" }).click();

      await page.getByRole("button", { name: LOCK_BOARD }).hover();
      await page.waitForTimeout(5 * PREFETCH_DELAY_MS);
      await page.reload();

      await expect(page.getByRole("button", { name: LOCK_BOARD })).toBeVisible();
    });
});
