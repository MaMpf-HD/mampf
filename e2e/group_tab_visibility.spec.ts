import { test, expect } from "./_support/fixtures";
import { enableFeature, disableFeature } from "./_support/backend";
import { LectureEditPage } from "./page-objects/lecture_edit_page";

/**
 * Integration test for the visibility of the group tab.
 */
test("Group tab visibility toggles with feature flag", async ({
  request,
  factory,
  teacher: { page, user },
}) => {
  const lecture = await factory.create("lecture", [], { teacher_id: user.id });

  const lectureEditPage = new LectureEditPage(page, lecture.id);

  // 1. Feature disabled
  await disableFeature(request, "roster_maintenance");
  await lectureEditPage.goto();
  await expect(lectureEditPage.groupsTab).not.toBeVisible();

  // 2. Enable feature
  await enableFeature(request, "roster_maintenance");
  await page.reload();
  await expect(lectureEditPage.groupsTab).toBeVisible();

  // 3. Disable feature
  await disableFeature(request, "roster_maintenance");
  await page.reload();
  await expect(lectureEditPage.groupsTab).not.toBeVisible();
});
