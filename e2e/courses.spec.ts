import { expect, test } from "./_support/fixtures";

test("can add tag to course", async ({ factory, admin: { page } }) => {
  const course = await factory.create("course");

  await page.goto(`/courses/${course.id}/edit`);
  await page.locator("#new-tag-button").click();
  await page.locator("#tag_notions_attributes_0_title").fill("Geometrie");
  await page.locator("#tag_notions_attributes_1_title").fill("Geometry");
  await page.locator(".col-12 > .btn-primary").click();
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
  await page.locator("#upload-image").setInputFiles("e2e/files/image.png");
  await page.getByRole("button", { name: "Upload" }).click();
  await page.getByRole("button", { name: "Save" }).click();
  await expect(page.getByText("image.png")).toBeVisible();
});

test("can detach course image", async ({ factory, admin: { page } }) => {
  const course = await factory.create("course", ["with_image"]);
  const term = await factory.create("term");
  await factory.create("lecture", [], { term_id: term.id, course_id: course.id });

  await page.goto(`/courses/${course.id}/edit`);
  await page.locator("#image_heading").getByText("Toggle").click();
  await expect(page.getByText("image.png")).toBeVisible();

  await page.locator("#detach-image").click();
  await expect(page.locator("#course_detach_image")).toHaveValue("true");
  await expect(page.locator("#image-meta")).toBeHidden();

  await page.getByRole("button", { name: "Save" }).click();
  await page.locator("#image_heading").getByText("Toggle").click();
  await expect(page.locator("#image-preview")).toHaveAttribute("src", "/no_course_information.png");
});
