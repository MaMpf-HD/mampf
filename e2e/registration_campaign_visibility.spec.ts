import { test, expect } from "./_support/fixtures";
import { enableFeature, disableFeature } from "./_support/backend";
import { LectureEditPage } from "./page-objects/lecture_edit_page";

/**
 * Integration test for the visibility of the registration campaign tab.
 */
test("Registration campaign tab visibility toggles with feature flag", async ({
  request,
  factory,
  teacher: { page, user },
}) => {
  const lecture = await factory.create("lecture", [], { teacher_id: user.id });

  const lectureEditPage = new LectureEditPage(page, lecture.id);

  // 1. Feature disabled
  await disableFeature(request, "registration_campaigns");
  await lectureEditPage.goto();
  await expect(lectureEditPage.campaignsTab).not.toBeVisible();

  // 2. Enable feature
  await enableFeature(request, "registration_campaigns");
  await page.reload();
  await expect(lectureEditPage.campaignsTab).toBeVisible();

  // 3. Disable feature
  await disableFeature(request, "registration_campaigns");
  await page.reload();
  await expect(lectureEditPage.campaignsTab).not.toBeVisible();
});
