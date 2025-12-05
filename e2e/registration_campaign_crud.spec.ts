import { test, expect } from "./_support/fixtures";
import { enableFeature } from "./_support/backend";
import { LectureEditPage } from "./page-objects/lecture_edit_page";

test.describe("Registration Campaigns CRUD", () => {
  test.beforeEach(async ({ request }) => {
    await enableFeature(request, "registration_campaigns");
  });

  test("Teacher can create a new campaign", async ({
    factory,
    teacher: { page, user },
  }) => {
    const lecture = await factory.create("lecture", [], { teacher_id: user.id });
    const lectureEditPage = new LectureEditPage(page, lecture.id);

    await lectureEditPage.goto();
    await expect(lectureEditPage.campaignsTab).toBeVisible();
    await lectureEditPage.campaignsTab.click();

    await expect(page.getByRole("button", { name: "New Campaign" })).toBeVisible();
    await page.getByRole("button", { name: "New Campaign" }).click();
    await expect(page.getByRole("heading", { name: "New Campaign" })).toBeVisible();

    await page.getByLabel("Title").fill("Exam Registration 2025");
    await page.getByLabel("Registration Deadline").fill("2025-12-31T23:59");
    await expect(page.getByRole("button", { name: "Save" })).toBeVisible();
    await page.getByRole("button", { name: "Save" }).click();

    await expect(page.getByRole("heading", { name: "Exam Registration 2025" })).toBeVisible();
    await expect(page.getByText("Draft")).toBeVisible();
  });

  test("Teacher can update an existing campaign", async ({
    factory,
    teacher: { page, user },
  }) => {
    // Setup: Create campaign via factory directly
    const lecture = await factory.create("lecture", [], { teacher_id: user.id });
    await factory.create("registration_campaign", [], {
      campaignable_id: lecture.id,
      campaignable_type: "Lecture",
      title: "Old Title",
    });

    const lectureEditPage = new LectureEditPage(page, lecture.id);
    await lectureEditPage.goto();
    await expect(lectureEditPage.campaignsTab).toBeVisible();
    await lectureEditPage.campaignsTab.click();

    await expect(page.getByText("Old Title")).toBeVisible();
    await page.getByText("Old Title").click();

    await expect(page.getByRole("tab", { name: "Settings" })).toBeVisible();
    await page.getByRole("tab", { name: "Settings" }).click();

    await expect(page.getByLabel("Title")).toBeVisible();
    await page.getByLabel("Title").fill("Updated Title");
    await expect(page.getByRole("button", { name: "Save" })).toBeVisible();
    await page.getByRole("button", { name: "Save" }).click();

    await expect(page.getByRole("heading", { name: "Updated Title" })).toBeVisible();
  });
});
