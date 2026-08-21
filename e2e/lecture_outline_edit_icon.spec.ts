import { expect, test } from "./_support/fixtures";

// The icon sits beside the heading, and everyone who may edit the lecture
// gets it -- a seminar's teacher is usually no editor of its course.
test.describe("the edit icon on the outline", () => {
  test("shows it to the teacher of a lecture", async ({ factory, teacher: { page, user } }) => {
    const lecture = await factory.create("lecture", ["released_for_all"], {
      teacher_id: user.id, locale: "en",
    });

    await page.goto(`/lectures/${lecture.id}/outline`);

    await expect(page.getByRole("link", { name: "Edit" })).toBeVisible();
  });

  test("puts it beside the heading, at the heading's size",
    async ({ factory, teacher: { page, user } }) => {
      const lecture = await factory.create("lecture", ["released_for_all"], {
        teacher_id: user.id, locale: "en",
      });

      await page.goto(`/lectures/${lecture.id}/outline`);

      const heading = page.getByRole("heading", { name: "Lecture Contents" });
      const icon = page.getByRole("link", { name: "Edit" });
      await expect(icon).toBeVisible();

      const headingBox = (await heading.boundingBox())!;
      const iconBox = (await icon.boundingBox())!;

      // Beside the heading rather than flushed to the far end of the row.
      expect(iconBox.x - (headingBox.x + headingBox.width)).toBeLessThan(24);
      // And drawn at the same size as the text it belongs to.
      expect(await icon.evaluate(el => getComputedStyle(el).fontSize))
        .toBe(await heading.evaluate(el => getComputedStyle(el).fontSize));
    });

  test("shows it to the teacher of a seminar", async ({ factory, teacher: { page, user } }) => {
    const seminar = await factory.create("lecture", ["released_for_all", "is_seminar"], {
      teacher_id: user.id, locale: "en",
    });

    await page.goto(`/lectures/${seminar.id}/outline`);

    await expect(page.getByRole("link", { name: "Edit" })).toBeVisible();
  });
});
