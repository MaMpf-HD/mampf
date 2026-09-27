import { expect, test } from "../_support/fixtures";
import { CampaignRegistrationPage } from "../page-objects/campaign_registrations_page";
import { ExamDashboardPage } from "../page-objects/exam_dashboard_page";
import { createLecture } from "./helpers";

/**
 * An exam is the fourth thing a student can register for, next to tutorials,
 * talks and cohorts. Its tile is drawn by the same generic view, so the tile
 * has to know what an exam looks like.
 */
test.describe("registering for an exam", () => {
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

    await student.page.goto(`/lectures/${lecture.id}`);
    await student.page.getByRole("heading", { name: "Main Exam" }).click();

    const option = student.page.getByTestId("registration-option");
    await expect(option).toContainText("Main Exam");
    await expect(option).toContainText("Lecture Hall 1");
    await expect(student.page.getByText(
      "Register for this exam. Your place is confirmed right away.",
    )).toBeVisible();
    await expect(student.page.getByText("Register for a group")).toHaveCount(0);
  });

  test("lets the student register, and holds the seat only from finalization on", async ({
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
    const page = new ExamDashboardPage(teacher.page, lecture.id);
    await page.open("Main Exam");
    await page.tab("Registrations").click();
    teacher.page.on("dialog", dialog => dialog.accept());
    await page.pane.getByRole("button", { name: "Start Registration" }).click();
    await expect(page.pane.getByRole("button", { name: "End Registration" }))
      .toBeVisible();

    await student.page.goto(`/lectures/${lecture.id}`);
    await student.page.getByRole("heading", { name: "Main Exam" }).click();
    await student.page.getByRole("button", { name: "Register for Main Exam" }).click();

    const home = new CampaignRegistrationPage(student.page, lecture.id);
    await expect(home.campaign("Main Exam")).toContainText("Registered");
    await expect(student.page.getByRole("button", { name: "Withdraw from Main Exam" }))
      .toBeVisible();

    // the exam list is built when the registration is finalized
    await student.page.reload();
    await expect(student.page.getByTestId("participation-row")
      .filter({ hasText: "Main Exam" })).toHaveCount(0);
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

    await student.page.goto(`/lectures/${lecture.id}`);
    await expect(student.page.getByTestId("participation-row")).toHaveCount(0);

    // a seat is what an entry in the exam's roster means
    await factory.create("exam_roster_entry", [], {
      exam_id: exam.id,
      user_id: student.user.id,
    });

    await student.page.goto(`/lectures/${lecture.id}`);
    const held = student.page.getByTestId("participation-row").filter({ hasText: "Main Exam" });
    await expect(held.getByText("Exam · Main Exam")).toBeVisible();
    await expect(held.getByText("On the exam list")).toBeVisible();
    await expect(held.getByText("Lecture Hall 1")).toBeVisible();
  });
});
