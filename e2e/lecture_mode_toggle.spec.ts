import { expect, test } from "./_support/fixtures";

// Staff have no administration area; they switch between viewing and editing
// a lecture right on its pages.
test.describe("switching between viewing and editing a lecture", () => {
  test("lets the teacher switch to the edit page and back",
    async ({ factory, teacher: { page, user } }) => {
      const lecture = await factory.create("lecture", ["released_for_all"], {
        teacher_id: user.id,
      });

      await page.goto(`/lectures/${lecture.id}/outline`);
      const toggle = page.getByRole("navigation", {
        name: "Switch between viewing and editing the lecture",
      });
      const sidebar = page.locator("#sidebar");
      await expect(toggle.getByRole("link", { name: "View" }))
        .toHaveAttribute("aria-current", "page");
      await expect(sidebar).toBeVisible();

      // a marker on the window survives only if the page is not loaded anew
      await page.evaluate(() => { (window as any).stillSamePage = true; });

      await toggle.getByRole("link", { name: "Edit" }).click();
      await expect(page).toHaveURL(`/lectures/${lecture.id}/edit`);
      await expect(toggle.getByRole("link", { name: "Edit" }))
        .toHaveAttribute("aria-current", "page");
      // the magenta of the edit page's tabs
      await expect(toggle.getByRole("link", { name: "Edit" }))
        .toHaveCSS("background-color", "rgb(130, 26, 59)");
      await expect(sidebar).toHaveCount(0);
      await expect(page.locator(".admin-background")).toBeVisible();

      await toggle.getByRole("link", { name: "View" }).click();
      await expect(page).not.toHaveURL(/\/edit$/);
      await expect(toggle.getByRole("link", { name: "View" }))
        .toHaveAttribute("aria-current", "page");
      await expect(sidebar).toBeVisible();
      await expect(page.locator(".admin-background")).toHaveCount(0);

      expect(await page.evaluate(() => (window as any).stillSamePage)).toBe(true);
    });

  test("switches to editing in place from the pencil on the outline",
    async ({ factory, teacher: { page, user } }) => {
      const lecture = await factory.create("lecture", ["released_for_all"], {
        teacher_id: user.id,
      });

      await page.goto(`/lectures/${lecture.id}/outline`);
      await page.evaluate(() => { (window as any).stillSamePage = true; });
      await page.getByRole("main").getByRole("link", { name: "Edit" }).click();

      await expect(page).toHaveURL(`/lectures/${lecture.id}/edit`);
      await expect(page.getByTestId("content-tab-btn")).toBeVisible();
      expect(await page.evaluate(() => (window as any).stillSamePage)).toBe(true);
    });

  test("leads back to the dashboard", async ({ factory, student: { page, user } }) => {
    const course = await factory.create("course", [], { title: "Linear Algebra" });
    const lecture = await factory.create("lecture", ["released_for_all"], { course_id: course.id });
    await factory.create("lecture_bookmark", [], { user_id: user.id, lecture_id: lecture.id });

    await page.goto(`/lectures/${lecture.id}/outline`);
    await expect(page.getByTestId("lecture-title-bar")).toContainText("Linear Algebra");
    await page.getByRole("link", { name: "Back to the dashboard" }).click();

    await expect(page).toHaveURL(/\/main\/start$/);
  });

  test("gives teachers no administration icon", async ({ teacher: { page } }) => {
    await page.goto("/main/start");

    await expect(page.getByTitle("administration")).toHaveCount(0);
  });

  test("shows no toggle to students", async ({ factory, student: { page } }) => {
    const lecture = await factory.create("lecture", ["released_for_all"]);

    await page.goto(`/lectures/${lecture.id}/outline`);

    await expect(page.getByRole("navigation", {
      name: "Switch between viewing and editing the lecture",
    })).toHaveCount(0);
  });
});
