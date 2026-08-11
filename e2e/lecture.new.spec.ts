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

  // The form is fetched into a turbo frame, and Turbo refetches any frame that
  // still carries a src when it restores a cached page. Emptying the frame is
  // therefore not enough — otherwise the form is back after the back button.
  test("Leaves nothing behind that would fetch the form back", async ({
    factory,
    admin: { page },
  }) => {
    const course = await factory.create("course");
    await factory.create("term");
    const frame = page.locator("#new_lecture");

    await page.goto("/administration");
    await page.getByTestId("new-lecture-button-admin-index").click();
    await expect(page.getByTestId("new-lecture-submit")).toBeVisible();
    await expect(frame).toHaveAttribute("src", /lectures\/new/);

    await page.getByRole("button", { name: "Cancel" }).click();
    await expect(page.getByTestId("new-lecture-submit")).toBeHidden();
    await expect(frame).not.toHaveAttribute("src", /./);

    await page.getByTestId("new-lecture-button-admin-index").click();
    await page.getByTestId("new-lecture-course-select").selectOption({ label: course.title });
    await page.keyboard.press("Escape");
    await page.getByTestId("new-lecture-submit").click();
    await expect(page.getByRole("alert")).toBeVisible();
    await expect(frame).not.toHaveAttribute("src", /./);
  });

  test("Leaves the course edit page usable after creating a lecture", async ({
    factory,
    admin: { page, user },
  }) => {
    const course = await factory.create("course");
    const term = await factory.create("term");

    await page.goto(`/courses/${course.id}/edit`);
    await testCreateNewLecture(page, user, course, term, true);

    await expect(page.getByRole("dialog", { name: "Create an event series" })).toBeHidden();
    await expect(page.getByRole("link", { name: user.name })).toBeVisible();
  });

  test("Closes the new lecture dialog without creating anything", async ({
    factory,
    admin: { page },
  }) => {
    const course = await factory.create("course");
    await factory.create("term");

    await page.goto(`/courses/${course.id}/edit`);

    const dialog = page.getByRole("dialog", { name: "Create an event series" });
    await page.getByTestId("new-lecture-button-course-edit").click();
    await expect(dialog).toBeVisible();

    await dialog.getByRole("button", { name: "Close" }).click();
    await expect(dialog).toBeHidden();
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
  const button = isCoursePrefilled
    ? "new-lecture-button-course-edit"
    : "new-lecture-button-admin-index";

  const lectureNewPromise = isCoursePrefilled
    ? page.waitForResponse(
        response => response.url().includes("/lectures/new") && response.status() === 200,
      )
    : null;
  await page.getByTestId(button).click();
  if (lectureNewPromise) await lectureNewPromise;

  if (!isCoursePrefilled) {
    const selectDiv = page.getByTestId("new-lecture-course-select");
    await selectDiv.selectOption({ label: course.title });
  }

  await page.keyboard.press("Escape"); // close the course dropdown
  await page.getByTestId("new-lecture-submit").click();

  const alert = page.getByRole("alert");
  await expect(alert).toBeVisible();
  await expect(alert).toContainText(course.title);
  await expect(alert).toContainText(term.season);
  await expect(alert).toContainText(user.name);
  await expect(alert).toContainText("successfully");
}
