import { Page, expect, test } from "./_support/fixtures";

// Everything here is reached the way a person reaches it — through Turbo, not
// through a reload — because that is where the page used to fall silent.
async function visitEdit(page: Page, lectureId: number, tab: string) {
  await page.goto(`/lectures/${lectureId}/home`);
  await page.evaluate((url) => {
    window.Turbo.visit(url);
  }, `/lectures/${lectureId}/edit?tab=${tab}`);
  await page.waitForLoadState("networkidle");
}

test.describe("the lecture edit page", () => {
  test("announces unsaved changes on every tab that has a form",
    async ({ factory, admin: { page } }) => {
      const lecture = await factory.create("lecture", ["released_for_all"], { locale: "en" });

      for (const [tab, form, warning] of [
        ["people", "#lecture-form", "#lecture-basics-warning"],
        ["settings", "#lecture-preferences-form", "#lecture-preferences-warning"],
        ["assignments", "#lecture-assignments-form", "#lecture-assignments-warning"],
      ] as const) {
        await visitEdit(page, lecture.id, tab);
        await expect(page.locator(warning)).toBeHidden();

        await page.locator(`${form} :is(input, select, textarea)`).first()
          .dispatchEvent("change", { bubbles: true });

        await expect(page.locator(warning)).toBeVisible();
      }
    });

  test("puts the assignments tab back when the change is discarded",
    async ({ factory, admin: { page } }) => {
      const lecture = await factory.create("lecture", ["released_for_all"], { locale: "en" });
      await visitEdit(page, lecture.id, "assignments");
      const teamSize = page.getByLabel("maximal team size for submissions");
      const saved = await teamSize.inputValue();

      await teamSize.fill("7");
      await teamSize.dispatchEvent("change", { bubbles: true });
      await expect(page.locator("#lecture-assignments-warning")).toBeVisible();

      await page.locator("#cancel-lecture-assignments").click();

      await expect(page.locator("#lecture-assignments-warning")).toBeHidden();
      await expect(teamSize).toHaveValue(saved);
    });

  test("only lets the start section be picked with absolute numbering on",
    async ({ factory, admin: { page } }) => {
      const lecture = await factory.create("lecture", ["released_for_all"], { locale: "en" });
      await visitEdit(page, lecture.id, "settings");
      const startSection = page.getByLabel("Nummer of the first section");

      await expect(startSection).toBeDisabled();
      const absoluteNumbering = page.getByLabel("absolute numbering");
      await absoluteNumbering.check();
      await expect(startSection).toBeEnabled();

      await absoluteNumbering.uncheck();
      await expect(startSection).toBeDisabled();
    });

  test("fills the subscriber list on the way in",
    async ({ factory, student, admin: { page } }) => {
      const lecture = await factory.create("lecture", ["released_for_all"], { locale: "en" });
      await factory.create("lecture_user_join", [], {
        lecture_id: lecture.id, user_id: student.user.id,
      });

      await visitEdit(page, lecture.id, "people");

      await expect(page.locator("#lectureUserModalContent"))
        .toContainText(student.user.email);
    });

  test("folds the media column away and back", async ({ factory, admin: { page } }) => {
    const lecture = await factory.create("lecture", ["released_for_all"], { locale: "en" });
    await visitEdit(page, lecture.id, "content");
    const mediaCard = page.locator("#lecture-media-card");
    const showButton = page.getByTitle("Show media");

    await expect(mediaCard).toBeVisible();
    await page.getByTitle("Hide Media").click();

    await expect(mediaCard).toBeHidden();
    await expect(showButton).toBeVisible();

    await showButton.click();

    await expect(mediaCard).toBeVisible();
    await expect(showButton).toBeHidden();
  });
});
