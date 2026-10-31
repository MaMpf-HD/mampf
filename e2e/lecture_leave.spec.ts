import { expect, test } from "./_support/fixtures";

test.describe("people who left a course", () => {
  test("are listed for the lecturer, who can readmit them", async ({ factory, teacher }) => {
    const lecture = await factory.create("lecture", ["released_for_all"], {
      teacher_id: teacher.user.id,
    });
    const former = await factory.create("confirmed_user", [], { name_in_tutorials: "Lina Berg" });
    await factory.create("lecture_membership", [], {
      lecture_id: lecture.id,
      user_id: former.id,
      excluded_at: new Date().toISOString(),
      excluded_by_id: former.id,
    });
    const { page } = teacher;

    await page.goto(`/lectures/${lecture.id}/performance/records`);
    await page.getByRole("combobox", { name: "All participants" })
      .selectOption({ label: "Left the course" });
    await expect(page.getByRole("row").filter({ hasText: "Lina Berg" }))
      .toContainText("Left the course");

    await page.goto(`/lectures/${lecture.id}/edit?tab=participants`);
    await page.getByRole("link", { name: /^Left/ }).click();
    const row = page.getByRole("row").filter({ hasText: "Lina Berg" });
    await expect(row).toContainText("Left on");

    page.once("dialog", dialog => void dialog.accept());
    await row.getByRole("button", { name: "Readmit" }).click();

    await expect(page.getByRole("row").filter({ hasText: "Lina Berg" })).toHaveCount(0);
    await page.getByRole("link", { name: /^Enrolled/ }).click();
    await expect(page.getByRole("row").filter({ hasText: "Lina Berg" })).toBeVisible();
  });
});
