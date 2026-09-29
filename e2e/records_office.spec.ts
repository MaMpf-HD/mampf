import { readFile } from "node:fs/promises";
import { parseCsv } from "./_support/csv";
import { expect, test } from "./_support/fixtures";

test.describe("records office", () => {
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

      await student.page.goto("/");
      await expect(student.page.getByRole("link", { name: "Records office" })).toHaveCount(0);

      await admin.page.goto(`/support/users/${student.user.id}/edit`);
      await admin.page.getByRole("checkbox", { name: "Records office" }).check();
      await admin.page.getByRole("button", { name: "Save", exact: true }).click();
      await expect(admin.page.getByText("The changes have been saved.")).toBeVisible();
      await expect(admin.page.getByRole("checkbox", { name: "Records office" })).toBeChecked();

      await student.page.reload();
      await student.page.getByRole("link", { name: "Records office" }).click();
      await expect(student.page.getByRole("heading", { name: "Records office" })).toBeVisible();
      await expect(student.page.getByRole("region", { name: lectureTitle })).toHaveCount(0);

      await student.page.getByLabel("Term").selectOption({ label: "SS 2030" });
      await expect(student.page).toHaveURL(/term=SS30/);
      const card = student.page.getByRole("region", { name: lectureTitle });
      const row = card.getByRole("row", { name: /Tuesday group/ });
      await expect(row).toContainText("1 / 12");

      const downloadPromise = student.page.waitForEvent("download");
      await row.getByRole("link", { name: "Emails of Tuesday group" }).click();
      const filePath = await (await downloadPromise).path();
      const rows = parseCsv((await readFile(filePath, "utf-8")).replace(/^\uFEFF/, ""));

      expect(rows[0]).toEqual(["Last name", "First name", "Matriculation number", "Email"]);
      expect(rows[1][3]).toBe(student.user.email);
    });
});
