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
    const menu = page.getByTestId("quick-access-menu");
    const toggle = page.getByRole("button", { name: "Quick Access", exact: true });

    await page.goto("/");
    await toggle.click();
    await expect(menu).toContainText("You haven't pinned any lectures yet.");
    await expect(menu).toContainText("Open a lecture to pin it here.");

    await page.goto(`/lectures/${lecture.id}`);
    await toggle.click();
    await menu.getByRole("link", { name: "Pin AdvCalc" }).click();
    // wait for the Turbo Stream to swap the menu before reopening it
    await expect(menu.getByText("Unpin AdvCalc")).toBeAttached();

    await toggle.click();
    await expect(menu.getByRole("link", { name: "Unpin AdvCalc" })).toBeVisible();
    await expect(menu.getByRole("link", { name: /^AdvCalc/ })).toBeVisible();
    await expect(menu).not.toContainText("Open a lecture to pin it here.");

    await page.goto("/");
    await toggle.click();
    await menu.getByRole("link", { name: "AdvCalc" }).click();
    await expect(page).toHaveURL(`/lectures/${lecture.id}`);

    await toggle.click();
    await menu.getByRole("link", { name: "Unpin AdvCalc" }).click();
    await expect(menu.getByText("Pin AdvCalc")).toBeAttached();
    await toggle.click();
    await expect(menu.getByRole("link", { name: "Pin AdvCalc" })).toBeVisible();
    await expect(menu).toContainText("You haven't pinned any lectures yet.");
  });
});
