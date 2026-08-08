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
    await expect(student.page.getByText(
      "Register for this exam. Your place is confirmed right away.",
    )).toBeVisible();
    await expect(student.page.getByText("Register for a group")).toHaveCount(0);
  });

  test("shows the seat once the student has one", async ({
    factory,
    teacher,
    student,
  }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    await factory.create("lecture_membership", [], {
      lecture_id: lecture.id,
      user_id: student.user.id,
    });
    const exam = await factory.create("exam", ["with_date"], {
      lecture_id: lecture.id,
      title: "Main Exam",
      location: "Lecture Hall 1",
    });

    await student.page.goto(`/lectures/${lecture.id}/home`);
    await expect(
      student.page.getByText("You have not been assigned to a group yet."),
    ).toBeVisible();

    // a seat is what an entry in the exam's roster means
    await factory.create("exam_roster_entry", [], {
      exam_id: exam.id,
      user_id: student.user.id,
    });

    await student.page.goto(`/lectures/${lecture.id}/home`);
    const held = student.page.locator("#student_registration_rosterized_entries");
    await expect(held.getByText("Exam", { exact: true })).toBeVisible();
    await expect(held.getByText("Main Exam")).toBeVisible();
    await expect(held.getByText("Lecture Hall 1")).toBeVisible();
    await expect(
      student.page.getByText("You have not been assigned to a group yet."),
    ).toHaveCount(0);
  });
});
