import { test, expect } from "./_support/fixtures";
import { LectureEditPage } from "./page-objects/lecture_edit_page";

/**
 * Integration test for the visibility of the group tab.
 */
test("Group tab is offered on the lecture edit page", async ({
  factory,
  teacher: { page, user },
}) => {
  const lecture = await factory.create("lecture", [], { teacher_id: user.id });

  const lectureEditPage = new LectureEditPage(page, lecture.id);
  await lectureEditPage.goto();

  await expect(lectureEditPage.groupsTab).toBeVisible();
});
