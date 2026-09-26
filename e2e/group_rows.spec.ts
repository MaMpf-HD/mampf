import { expect, test } from "./_support/fixtures";

/**
 * The Groups tab lists a lecture's groups as rows. A row opens its roster in
 * the side panel, from a click or from its title with the keyboard, and a
 * student in that roster can be moved without dragging.
 */
test.describe("the group rows", () => {
  test("open a roster from the title with the keyboard and take the focus back",
    async ({ factory, student, teacher: { page, user } }) => {
      const lecture = await factory.create("lecture", [], { teacher_id: user.id });
      const tutorial = await factory.create("tutorial", [], {
        lecture_id: lecture.id, title: "Mo 10", capacity: 8, skip_campaigns: true,
      });
      await tutorial.__call("add_user_to_roster!", student.user);

      await page.goto(`/lectures/${lecture.id}/edit?tab=groups`);
      const row = page.getByTestId("group-row").filter({ hasText: "Mo 10" });
      await expect(row).toContainText("1 / 8 members");

      const title = row.getByRole("button", { name: "Mo 10", exact: true });
      await expect(title).toHaveAttribute("aria-expanded", "false");
      await title.focus();
      await page.keyboard.press("Enter");

      const panel = page.locator("#tutorial-roster-side-panel");
      await expect(panel.getByRole("heading", { name: "Participants" })).toBeFocused();
      await expect(title).toHaveAttribute("aria-expanded", "true");
      await expect(panel.getByRole("button", {
        name: `Copy email address: ${student.user.email}`,
      })).toBeVisible();

      await panel.getByRole("button", { name: "Close", exact: true }).click();
      await expect(title).toBeFocused();
      await expect(title).toHaveAttribute("aria-expanded", "false");
    });

  test("move a student to another tutorial without dragging",
    async ({ factory, student, teacher: { page, user } }) => {
      const lecture = await factory.create("lecture", [], { teacher_id: user.id });
      const monday = await factory.create("tutorial", [], {
        lecture_id: lecture.id, title: "Mo 10", capacity: 8, skip_campaigns: true,
      });
      await factory.create("tutorial", [], {
        lecture_id: lecture.id, title: "Di 12", capacity: 8, skip_campaigns: true,
      });
      await monday.__call("add_user_to_roster!", student.user);

      await page.goto(`/lectures/${lecture.id}/edit?tab=groups`);
      await page.getByRole("heading", { name: "Mo 10", exact: true }).click();

      const panel = page.locator("#tutorial-roster-side-panel");
      await panel.getByRole("button", { name: /to another group/ }).click();

      const dialog = page.getByRole("dialog", { name: /^Move or add .* to …$/ });
      await expect(dialog.getByRole("button", { name: /Mo 10/ })).toHaveCount(0);
      await dialog.getByRole("button", { name: /Di 12/ }).click();

      const rows = page.getByTestId("group-row");
      await expect(rows.filter({ hasText: "Di 12" })).toContainText("1 / 8 members");
      await expect(rows.filter({ hasText: "Mo 10" })).toContainText("0 / 8 members");
    });
});
