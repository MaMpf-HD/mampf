import { expect, test } from "./_support/fixtures";

test.describe("dean's office", () => {
  test("is opened to somebody by an admin, who then reads a term's courses",
    async ({ admin, student, factory }) => {
      const older = await factory.create("term", [], { season: "SS", year: 2030 });
      await factory.create("term", [], { season: "WS", year: 2030 });
      const course = await factory.create("course", [], { title: "Linear Algebra" });
      const lecture = await factory.create("lecture", [],
        { term_id: older.id, course_id: course.id });
      const tutorial = await factory.create("tutorial", [],
        { lecture_id: lecture.id, title: "Tuesday group", capacity: 12, location: "INF 205" });
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

      await student.page.reload();
      await student.page.getByRole("link", { name: "Dean's office" }).click();
      await expect(student.page.getByRole("heading", { name: "Dean's office" })).toBeVisible();

      await student.page.getByLabel("Term").selectOption({ label: "SS 2030" });
      await expect(student.page).toHaveURL(/term=SS30/);

      // one line per lecture: its students, its tutorials with their places
      const lectures = student.page.getByRole("table", { name: "Lectures" });
      const row = lectures.getByRole("row", { name: /Linear Algebra/ });
      await expect(row).toContainText("Allocated");
      await expect(row).toContainText("1 tutorial");

      const toggle = lectures.getByRole("button", { name: /Linear Algebra/ });
      await toggle.click();
      await expect(toggle).toHaveAttribute("aria-expanded", "true");
      const groups = student.page.getByRole("table", { name: "Groups" });
      const group = groups.getByRole("row", { name: /Tuesday group/ });
      await expect(group).toContainText("INF 205");
      await expect(group).toContainText("1");

      // a lecture without registration is only named, in a list of its own
      const unregistered = student.page.getByText("1 lecture without registration in MaMpf");
      await expect(unregistered).toBeVisible();
      await expect(student.page.getByText("Number Theory")).toBeHidden();

      const search = student.page.getByRole("searchbox", { name: "Search" });
      await search.fill("number");
      await expect(student.page.getByText("Number Theory")).toBeVisible();
      await expect(lectures).toBeHidden();

      await search.fill("no such course");
      await expect(student.page.getByRole("status")).toHaveText("No course matches your search.");
      await search.fill("");
      await expect(lectures).toBeVisible();

      await student.page.getByRole("link", { name: "by state of the registration" }).click();
      await expect(student.page).toHaveURL(/order=phase/);
      await expect(student.page.getByRole("columnheader", { name: "Allocated" }))
        .toBeVisible();

      await student.page.setViewportSize({ width: 390, height: 800 });
      const overflow = await student.page.evaluate(() =>
        document.documentElement.scrollWidth > document.documentElement.clientWidth);
      expect(overflow).toBe(false);
    });
});
