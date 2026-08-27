import { expect, test } from "./_support/fixtures";

// The lecture scripts are module tags in the page body: on the visit that first
// loads them, Turbo has announced turbo:load long before they are evaluated.
test("shows the save bar after arriving through an in-app visit",
  async ({ factory, admin: { page } }) => {
    const lecture = await factory.create("lecture", ["released_for_all"], { locale: "en" });
    const warning = page.locator("#lecture-basics-warning");

    await page.goto(`/lectures/${lecture.id}/home`);
    await page.evaluate((url) => {
      window.Turbo.visit(url);
    }, `/lectures/${lecture.id}/edit?tab=people`);
    await expect(page.locator("#lecture-form")).toBeVisible();
    await expect(warning).toBeHidden();

    // The page's scripts arrive as modules, after Turbo has swapped the body.
    await page.waitForLoadState("networkidle");

    // What TomSelect does once an editor is picked.
    await page.locator("#lecture_editors_select select")
      .dispatchEvent("change", { bubbles: true });

    await expect(warning).toBeVisible();
  });
