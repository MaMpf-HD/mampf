import { expect, Page, test } from "./_support/fixtures";

test.describe("Create new medium button", () => {
  /**
   * Closes the dialog until it is gone: Bootstrap ignores a Close while the
   * modal is still sliding in, which a busy CI runner makes likely.
   */
  async function expectSort(page: Page, sort: string, expectedString: RegExp) {
    await page.getByRole("tab", { name: sort }).click();
    await page.getByTitle("create medium").click();
    const dialog = page.getByRole("dialog", { name: "create new medium" });
    await expect(dialog.getByLabel("Type")).toHaveValue(expectedString);
    await expect(async () => {
      if (await dialog.isVisible()) {
        await dialog.getByRole("button", { name: "Close" }).click({ timeout: 1000 });
      }
      await expect(dialog).toBeHidden({ timeout: 1000 });
    }).toPass();
  }

  test("lecture edit view: sort is synced with currently selected tab",
    async ({ factory, teacher: { page, user } }) => {
      const lecture = await factory.create("lecture", [], { teacher_id: user.id });
      await page.goto(`/lectures/${lecture.id}/edit`);
      await expectSort(page, "exercises", /exercise/i);
      await expectSort(page, "script", /script/i);
    });

  test("course edit view: sort is synced with currently selected tab",
    async ({ factory, teacher: { page, user } }) => {
      const course = await factory.create("course", ["with_editor_by_id"], { editor_id: user.id });
      await page.goto(`/courses/${course.id}/edit`);
      await expectSort(page, "exercises", /exercise/i);
      await expectSort(page, "script", /script/i);
    });
});
