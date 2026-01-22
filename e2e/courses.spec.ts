import { expect, test } from "./_support/fixtures";
import { LecturePage } from "./page-objects/lecture_page";

test.describe("admin", () => {
  test("can add tag to course", async ({ factory, admin: { page } }) => {
    const course = await factory.create("course");

    await page.goto(`/courses/${course.id}/edit`);
    await page.locator("#new-tag-button").click();
    await page.locator("#tag_notions_attributes_0_title").fill("Geometrie");
    await page.waitForTimeout(100);
    await page.locator("#tag_notions_attributes_1_title").fill("Geometry");
    await page.locator(".col-12 > .btn-primary").click();
    await page.waitForTimeout(100);
    await expect(page.getByText("Geometrie (Geometry)×")).toBeVisible();
  });

  test("can set editor in course", async ({ factory, admin: { page }, teacher: { user } }) => {
    const course = await factory.create("course");

    await page.goto(`/courses/${course.id}/edit`);
    await page.locator("#course_editor_ids-ts-control").click();
    await page.locator("#course_editor_ids-ts-control").fill("tea");
    await page.getByText(user.email).click();
    await page.locator(".btn-primary").click();
    await expect(page.getByText(`teacher (public, 0) (${user.email})×`)).toBeVisible();
  });

  test("can create course", async ({ admin: { page } }) => {
    await page.goto("/administration");
    await page.getByTitle("Create Course").click();
    await page.locator('input[name="course[title]"]').fill("Lineare Algebra I");
    await page.locator('input[name="course[short_title]"]').fill("LA I");
    await page.locator('input[type="submit"]').click();
    await expect(page.getByRole("link", { name: "Lineare Algebra I" })).toBeVisible();
  });

  test("can set course image", async ({ factory, admin: { page } }) => {
    const course = await factory.create("course");
    const term = await factory.create("term");
    await factory.create("lecture", [], { term_id: term.id, course_id: course.id });

    await page.goto(`/courses/${course.id}/edit`);
    await page.locator("#image_heading").getByText("Toggle").click();

    const fileChooserPromise = page.waitForEvent("filechooser");
    await page.getByText("File", { exact: true }).click();
    const fileChooser = await fileChooserPromise;
    await fileChooser.setFiles("e2e/files/image.png");

    await page.getByRole("button", { name: "Upload" }).click();
    await page.waitForTimeout(100);
    await page.getByRole("button", { name: "Save" }).click();
    await expect(page.getByText("image.png")).toBeVisible();
  });
});

test.describe("teacher", () => {
  test("can subscribe to unpublished on page", async ({ factory, teacher: { page, user } }) => {
    const lecture = await factory.create("lecture", [], { teacher_id: user.id });
    await new LecturePage(page, lecture.id).goto();
    await expect(page.getByRole("heading", { name: "Attention" })).toBeVisible();
    await page.getByRole("button", { name: "Subscribe event series" }).click();
    await expect(page.getByRole("heading", { name: "Lecture Contents" })).toBeVisible();
  });
});

test.describe("student", () => {
  test("can subscribe", async ({ factory, student: { page } }) => {
    for (let i = 0; i < 6; i++) {
      await factory.create("lecture", ["released_for_all"]);
    }

    await page.goto("/main/start");
    await page.getByRole("button", { name: "Lecture Search" }).click();
    await page.getByRole("button", { name: "Search", exact: true }).click();
    await page.getByTitle("Subscribe").nth(0).click();
    await expect(page.getByTitle("Unsubscribe").nth(0)).toBeVisible();
  });

  test("can subscribe on page", async ({ factory, student: { page } }) => {
    const lecture = await factory.create("lecture", ["released_for_all"]);

    await new LecturePage(page, lecture.id).goto();
    await expect(page.getByRole("heading", { name: "Attention" })).toBeVisible();
    await page.getByRole("button", { name: "Subscribe event series" }).click();
    await expect(page.getByRole("heading", { name: "Lecture Contents" })).toBeVisible();
  });

  test("is blocked to subscribe on page", async ({ factory, student: { page } }) => {
    const lecture = await factory.create("lecture", [],
      { released: "locked", passphrase: "passphrase" });

    await new LecturePage(page, lecture.id).goto();
    await expect(page.getByRole("heading", { name: "Attention" })).toBeVisible();
    await page.getByRole("button", { name: "Subscribe event series" }).click();
    await expect(page.getByRole("heading", { name: "Lecture Contents" })).not.toBeVisible();
    await expect(page.getByRole("heading", { name: "Attention" })).toBeVisible();
  });

  test("can not subscribe on page to unpublished", async ({ factory, student: { page } }) => {
    const lecture = await factory.create("lecture");

    await new LecturePage(page, lecture.id).goto();
    await expect(page.getByText("You are not authorized to")).toBeVisible();
  });
});
