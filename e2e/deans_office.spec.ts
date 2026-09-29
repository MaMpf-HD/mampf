import { expect, test } from "./_support/fixtures";

test.describe("dean's office", () => {
  test("is opened to somebody by an admin, who then reads a term's groups",
    async ({ admin, student, factory }) => {
      const older = await factory.create("term", [], { season: "SS", year: 2030 });
      await factory.create("term", [], { season: "WS", year: 2030 });
      const course = await factory.create("course", [], { title: "Linear Algebra" });
      const lecture = await factory.create("lecture", [],
        { term_id: older.id, course_id: course.id });
      const lectureTitle = /Linear Algebra/;
      const tutorial = await factory.create("tutorial", [],
        { lecture_id: lecture.id, title: "Tuesday group", capacity: 12 });
      await factory.create("tutorial_membership", [],
        { tutorial_id: tutorial.id, user_id: student.user.id });
      const otherCourse = await factory.create("course", [], { title: "Number Theory" });
      await factory.create("lecture", [], { term_id: older.id, course_id: otherCourse.id });

      await student.page.goto("/");
      await expect(student.page.getByRole("link", { name: "Dean's office" })).toHaveCount(0);

      await admin.page.goto(`/support/users/${student.user.id}/edit`);
      await admin.page.getByRole("checkbox", { name: "Dean's office" }).check();
      await admin.page.getByRole("button", { name: "Save", exact: true }).click();
      await expect(admin.page.getByText("The changes have been saved.")).toBeVisible();
      await expect(admin.page.getByRole("checkbox", { name: "Dean's office" })).toBeChecked();

      await student.page.reload();
      await student.page.getByRole("link", { name: "Dean's office" }).click();
      await expect(student.page.getByRole("heading", { name: "Dean's office" })).toBeVisible();
      const toggle = student.page.getByRole("button", { name: lectureTitle });
      await expect(toggle).toHaveCount(0);

      await student.page.getByLabel("Term").selectOption({ label: "SS 2030" });
      await expect(student.page).toHaveURL(/term=SS30/);
      await expect(student.page.getByRole("rowheader", { name: /Number Theory/ })).toBeVisible();

      // one line per lecture; the filter keeps the one asked for
      await student.page.getByRole("searchbox", { name: "Filter" }).fill("linear");
      await expect(student.page.getByRole("rowheader", { name: /Number Theory/ })).toBeHidden();
      const groups = student.page.getByRole("table", { name: /Groups of .*Linear Algebra/ });
      await expect(groups).toBeHidden();

      await toggle.click();
      await expect(toggle).toHaveAttribute("aria-expanded", "true");
      const row = groups.getByRole("row", { name: /Tuesday group/ });
      await expect(row).toContainText("1 / 12");

      await student.page.getByRole("button", { name: "Hide all groups" }).click();
      await expect(groups).toBeHidden();
      await student.page.getByRole("button", { name: "Show all groups" }).click();
      await expect(groups).toBeVisible();
    });
});
