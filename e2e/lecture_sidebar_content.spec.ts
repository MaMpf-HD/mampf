import { expect, test } from "./_support/fixtures";

/**
 * See regression #1231.
 */
test.describe("lecture content for an editor who is not subscribed", () => {
  test("opens the general information", async ({ factory, teacher: { page, user } }) => {
    const lecture = await factory.create("lecture", ["released_for_all"], {
      teacher_id: user.id,
      organizational: true,
      organizational_concept: "<p>Exercise sheets appear on Wednesdays</p>",
    });

    expect(await lecture.__call("subscribed_by?", user)).toBe(false);

    await page.goto(`/lectures/${lecture.id}`);
    await page.getByRole("link", { name: "General Information" }).click();

    await expect(page.getByText("Exercise sheets appear on Wednesdays")).toBeVisible();
  });

  test("opens the course page", async ({ factory, teacher: { page, user } }) => {
    const lecture = await factory.create("lecture", ["released_for_all"], {
      teacher_id: user.id,
    });

    expect(await lecture.__call("subscribed_by?", user)).toBe(false);

    await page.goto(`/lectures/${lecture.id}`);
    await page.getByRole("link", { name: "Course" }).click();

    await expect(page.getByRole("heading", { name: "Course Editors" })).toBeVisible();
  });
});

test("shows a German lecture in the English of its reader",
  async ({ factory, teacher: { page, user } }) => {
    const course = await factory.create("course", [], { locale: "de" });
    const lecture = await factory.create("lecture", ["released_for_all"], {
      teacher_id: user.id,
      course_id: course.id,
      locale: "de",
      organizational: true,
      organizational_concept: "<p>Übungsblätter erscheinen mittwochs</p>",
    });

    await page.goto(`/lectures/${lecture.id}`);
    await expect(page.getByRole("link", { name: "Organisatorisches" })).toHaveCount(0);
    await page.getByRole("link", { name: "General Information" }).click();

    await expect(page.getByText("Übungsblätter erscheinen mittwochs")).toBeVisible();
  });
