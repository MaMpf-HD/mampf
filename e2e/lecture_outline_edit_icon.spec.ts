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

  test("shows it to the teacher of a seminar", async ({ factory, teacher: { page, user } }) => {
    const seminar = await factory.create("lecture", ["released_for_all", "is_seminar"], {
      teacher_id: user.id, locale: "en",
    });

    await page.goto(`/lectures/${seminar.id}/outline`);

    await expect(page.getByRole("link", { name: "Edit" })).toBeVisible();
  });
});
