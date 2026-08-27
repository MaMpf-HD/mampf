import { expect, test } from "./_support/fixtures";

test("can add tag to course", async ({ factory, admin: { page } }) => {
  const course = await factory.create("course");

  await page.goto(`/courses/${course.id}/edit`);
  await page.locator("#new-tag-button").click();
  await page.locator("#tag_notions_attributes_0_title").fill("Geometrie");
  await page.locator("#tag_notions_attributes_1_title").fill("Geometry");
  await page.locator("#newTagModal").getByRole("button", { name: "Save" }).click();
  await expect(page.getByTitle("Geometrie (Geometry)")).toBeVisible();
});

test("can set editor in course", async ({ factory, admin: { page }, teacher: { user } }) => {
  const course = await factory.create("course");

  await page.goto(`/courses/${course.id}/edit`);
  await page.locator("#course_editor_ids-ts-control").click();
  await page.locator("#course_editor_ids-ts-control").fill("tea");
  await page.getByText(user.email).click();
  await page.locator("#course-form").getByRole("button", { name: "Save" }).click();
  await expect(page.getByTitle(user.email)).toBeVisible();
});

test("can create course", async ({ admin: { page } }) => {
  await page.goto("/administration");
  await page.getByTitle("Create Course").click();
  const form = page.locator("#new-course-form");
  await form.getByLabel("Title", { exact: true }).fill("Lineare Algebra I");
  await form.getByLabel("Short title").fill("LA I");
  await form.getByRole("button", { name: "Save" }).click();
  await expect(page.getByRole("link", { name: "Lineare Algebra I" })).toBeVisible();
  // the count sits outside the list frame and has to be streamed along
  await expect(page.locator("#courses-count")).toHaveText("(1)");
});

// One creation at a time: both cards' plus buttons step aside for either form.
test("hides both create buttons while the course form is open", async ({
  factory,
  admin: { page },
}) => {
  await factory.create("course");
  await factory.create("term");

  const lecturePlus = page.getByTitle("Create an event series");
  const coursePlus = page.getByTitle("Create Course");

  await page.goto("/administration");
  await expect(lecturePlus).toBeVisible();
  await expect(coursePlus).toBeVisible();

  await coursePlus.click();
  await expect(page.getByRole("heading", { name: "Create new course" })).toBeVisible();
  await expect(lecturePlus).toBeHidden();
  await expect(coursePlus).toBeHidden();

  await page.getByRole("link", { name: "Cancel" }).click();
  await expect(page.getByRole("heading", { name: "Create new course" })).toBeHidden();
  await expect(lecturePlus).toBeVisible();
  await expect(coursePlus).toBeVisible();
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

  // the saved form comes back through a frame swap, which does not fire
  // turbo:load — without a rewired upload the next file silently goes nowhere
  await expect(page.locator("#image-preview"))
    .toHaveAttribute("src", /\/courses\/\d+\/image\/original/);
  await expect(page.locator("#upload-image")).toHaveCSS("display", "none");
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

test("finds a course by title and keeps the results in their frame", async ({
  factory,
  admin: { page },
}) => {
  await factory.create("course", [], { title: "Zahlentheorie" });
  await factory.create("course", [], { title: "Funktionalanalysis" });

  await page.goto("/administration/search");
  await page.getByRole("tab", { name: "Course Search" }).click();

  const form = page.locator('form[action*="/courses/search"]');
  await form.getByLabel("Full text").fill("Zahlen");
  await form.getByRole("button", { name: "Search" }).click();

  const results = page.locator("#courses-search-results");
  await expect(results.getByText("Zahlentheorie")).toBeVisible();
  await expect(results.getByText("Funktionalanalysis")).toBeHidden();

  await results.getByRole("link", { name: "Edit" }).click();

  await expect(page).toHaveURL(/\/courses\/\d+\/edit/);
  await expect(page.getByRole("heading", { name: "Zahlentheorie" })).toBeVisible();
});
