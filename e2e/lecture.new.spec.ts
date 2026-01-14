import { test, expect, Page } from "./_support/fixtures";
import { User } from "./_support/auth";

test.describe("New lecture as admin", () => {
  test("Creates new lecture (via index page)", async ({ factory, admin: { page, user } }) => {
    const course = await factory.create("course");
    const term = await factory.create("term");

    await page.goto("/administration");
    await testCreateNewLecture(page, user, course, term, false);
  });

  test("Creates new lecture (via course edit page)", async ({ factory, admin: { page, user } }) => {
    const course = await factory.create("course");
    const term = await factory.create("term");

    await page.goto(`/courses/${course.id}/edit`);
    await testCreateNewLecture(page, user, course, term, true);
  });
});

test.describe("New lecture as teacher (course editor)", () => {
  test("Creates new lecture (via index page)", async ({ factory, teacher: { page, user } }) => {
    const course = await factory.create("course", ["with_editor_by_id"], { editor_id: user.id });
    const term = await factory.create("term");

    await page.goto("/administration");
    await testCreateNewLecture(page, user, course, term, false);
  });

  test("Creates new lecture (via course edit page)", async ({ factory, teacher: { page, user } }) => {
    const course = await factory.create("course", ["with_editor_by_id"], { editor_id: user.id });
    const term = await factory.create("term");

    await page.goto(`/courses/${course.id}/edit`);
    await testCreateNewLecture(page, user, course, term, true);
  });
});

async function testCreateNewLecture(
  page: Page,
  user: User,
  course: any,
  term: any,
  isCoursePrefilled: boolean,
) {
  await page.getByTestId("new-lecture-button-admin-index").click();

  if (!isCoursePrefilled) {
    const selectDiv = page.getByTestId("new-lecture-course-select");
    await selectDiv.selectOption({ label: course.title });
  }

  await page.click("body", { position: { x: 0, y: 0 } }); // click outside to close dropdown
  await page.getByTestId("new-lecture-submit").click();

  const alert = page.locator("div.alert");
  await expect(alert).toBeVisible();
  await expect(alert).toContainText(course.title);
  await expect(alert).toContainText(term.season);
  await expect(alert).toContainText(user.name);
  await expect(alert).toContainText("successfully");
}
