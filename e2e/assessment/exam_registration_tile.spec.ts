import { enableFeature } from "../_support/backend";
import { expect, test } from "../_support/fixtures";
import { ExamDashboardPage } from "../page-objects/exam_dashboard_page";
import { createLecture } from "./helpers";

/**
 * An exam is the fourth thing a student can register for, next to tutorials,
 * talks and cohorts. Its tile is drawn by the same generic view, so the tile
 * has to know what an exam looks like.
 */
test.describe("registering for an exam", () => {
  test.beforeEach(async ({ request }) => {
    await enableFeature(request, "assessment_grading");
    await enableFeature(request, "registration_campaigns");
  });

  test("shows the exam on the student's lecture page", async ({
    factory,
    teacher,
    student,
  }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    await factory.create("lecture_membership", [], {
      lecture_id: lecture.id,
      user_id: student.user.id,
    });
    await factory.create("exam", ["with_date"], {
      lecture_id: lecture.id,
      title: "Main Exam",
      location: "Lecture Hall 1",
    });
    // the teacher opens registration, which is what puts the tile on the
    // student's page in the first place
    const page = new ExamDashboardPage(teacher.page, lecture.id);
    await page.open("Main Exam");
    await page.tab("Registrations").click();
    teacher.page.on("dialog", dialog => dialog.accept());
    await page.pane.getByRole("button", { name: "Start Registration" }).click();
    await expect(page.pane.getByRole("button", { name: "End Registration" }))
      .toBeVisible();

    await student.page.goto(`/lectures/${lecture.id}/home`);

    await expect(student.page.getByText("Main Exam")).toBeVisible();
    await expect(student.page.getByText("Lecture Hall 1")).toBeVisible();
  });
});
