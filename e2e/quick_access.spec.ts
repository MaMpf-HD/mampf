import { expect, test } from "./_support/fixtures";

test.describe("quick access", () => {
  test("pins a lecture without bookmarking it and unpins it again", async ({
    factory,
    student: { page },
  }) => {
    const course = await factory.create("course", [], {
      title: "Advanced Calculus", short_title: "AdvCalc",
    });
    const lecture = await factory.create("lecture", ["released_for_all"], {
      course_id: course.id,
    });
    const shortTitle = /AdvCalc/;
    const menu = page.getByTestId("quick-access-menu");
    const toggle = page.getByRole("button", { name: "Quick Access", exact: true }).last();

    await page.goto("/");
    await toggle.click();
    await expect(menu).toContainText("You have not pinned any lectures yet.");
    await expect(menu).toContainText("click the pin that will appear next to this menu");

    await page.goto(`/lectures/${lecture.id}`);
    await page.getByRole("button", { name: "Pin to Quick Access" }).click();
    const unpin = page.getByRole("button", { name: "Unpin from Quick Access" });
    await expect(unpin).toHaveAttribute("aria-pressed", "true");

    await toggle.click();
    await expect(menu.getByRole("link", { name: shortTitle })).toBeVisible();
    await expect(menu).not.toContainText("click the pin next to this menu");

    await page.goto("/");
    await toggle.click();
    await menu.getByRole("link", { name: shortTitle }).click();
    await expect(page).toHaveURL(new RegExp(`/lectures/${lecture.id}`));

    await unpin.click();
    await expect(page.getByRole("button", { name: "Pin to Quick Access" })).toBeVisible();
    await toggle.click();
    await expect(menu).toContainText("You have not pinned any lectures yet.");
  });
});
