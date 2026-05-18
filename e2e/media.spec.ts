import { expect, Page, test } from "./_support/fixtures";

test.describe("Create new medium button", () => {
  async function expectSort(page: Page, sort: string, expectedString: RegExp) {
    await page.getByRole("tab", { name: sort }).click();
    await page.getByTitle("create medium").click();
    await expect(page.getByRole("dialog", { name: "create new medium" }).getByLabel("Type"))
      .toHaveValue(expectedString);
    await page.getByRole("button", { name: "Close" }).click();
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
