import { expect, test } from "../_support/fixtures";
import { ExamDashboardPage } from "../page-objects/exam_dashboard_page";
import { addTask, createLecture, scoreTask } from "./helpers";

/**
 * A grade scheme turns points into grades. It is configured on the exam's
 * grades tab, lives as a draft while the teacher looks at what it would do, and
 * only writes grades once it is applied — so the screen has four states, and
 * the difference between them is what a teacher is deciding about.
 */
test.describe("grade schemes", () => {
  /** An exam whose points are in: one task worth 100, one student with 70. */
  async function markedExam(factory: any, teacherId: number) {
    const lecture = await createLecture(factory, teacherId);
    const exam = await factory.create("exam", ["with_date"], {
      lecture_id: lecture.id,
      title: "Main Exam",
    });
    const assessment = await exam.__call("assessment");
    const task = await addTask(factory, assessment.id, "Prove it", 100);
    const student = await factory.create("confirmed_user", [], {
      name_in_tutorials: "Ada Lovelace",
    });
    const participation = await factory.create("assessment_participation", [], {
      assessment_id: assessment.id,
      user_id: student.id,
      status: "reviewed",
      submitted_at: new Date().toISOString(),
    });
    await scoreTask(factory, task.id, participation.id, 70);

    return { lecture, exam };
  }

  async function openGrades(page: ExamDashboardPage) {
    await page.open("Main Exam");
    await page.tab("Grades").click();
  }

  test("creates one and keeps it as a draft", async ({ factory, teacher }) => {
    const { lecture } = await markedExam(factory, teacher.user.id);

    const page = new ExamDashboardPage(teacher.page, lecture.id);
    await openGrades(page);
    await teacher.page.getByRole("link", { name: "Create Grade Scheme" })
      .click();

    await expect(page.pane.getByText("Configure Grade Scheme")).toBeVisible();
    await page.pane.getByLabel("Excellence Threshold (Grade 1.0)").fill("90");
    await page.pane.getByLabel("Passing Threshold (Grade 4.0)").fill("50");
    await page.pane.getByRole("button", { name: "Auto-Generate Bands" }).click();
    await page.pane.getByRole("button", { name: "Save draft" }).click();

    await expect(teacher.page.getByText("Grade scheme saved.")).toBeVisible();
    await expect(page.pane.getByText("Grade scheme configured.")).toBeVisible();
    await expect(page.pane.getByRole("button", { name: "Apply Scheme" }))
      .toBeVisible();
  });

  test("applies one and records the grades", async ({ factory, teacher }) => {
    const { lecture, exam } = await markedExam(factory, teacher.user.id);
    await factory.create("assessment_grade_scheme", [], {
      assessment_id: (await exam.__call("assessment")).id,
    });

    const page = new ExamDashboardPage(teacher.page, lecture.id);
    await openGrades(page);
    teacher.page.on("dialog", dialog => dialog.accept());
    await page.pane.getByRole("button", { name: "Apply Scheme" }).click();

    await expect(teacher.page.getByText("Grade scheme applied!")).toBeVisible();
    await expect(teacher.page.getByRole("link", { name: "Revise Scheme" }))
      .toBeVisible();
  });

  test("discards a draft and offers to start over", async ({
    factory,
    teacher,
  }) => {
    const { lecture, exam } = await markedExam(factory, teacher.user.id);
    await factory.create("assessment_grade_scheme", [], {
      assessment_id: (await exam.__call("assessment")).id,
    });

    const page = new ExamDashboardPage(teacher.page, lecture.id);
    await openGrades(page);
    teacher.page.on("dialog", dialog => dialog.accept());
    await page.pane.getByRole("button", { name: "Discard Scheme" }).click();

    await expect(teacher.page.getByText("Grade scheme discarded.")).toBeVisible();
    await expect(page.pane.getByRole("link", { name: "Create Grade Scheme" }))
      .toBeVisible();
  });

  test("shows the fields that belong to the chosen mode", async ({
    factory,
    teacher,
  }) => {
    const { lecture } = await markedExam(factory, teacher.user.id);

    const page = new ExamDashboardPage(teacher.page, lecture.id);
    await openGrades(page);
    await teacher.page.getByRole("link", { name: "Create Grade Scheme" })
      .click();

    await expect(page.pane.getByLabel("Passing Threshold (Grade 4.0)")).toBeVisible();

    await page.pane.getByRole("button", { name: "Anchor + Step" }).click();
    await expect(page.pane.getByLabel("Grade Step (Δ)")).toBeVisible();
    await expect(page.pane.getByLabel("Excellence Threshold (Grade 1.0)"))
      .toBeHidden();
  });

  test("warns while the points are still being entered", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    const exam = await factory.create("exam", ["with_date"], {
      lecture_id: lecture.id,
      title: "Main Exam",
    });
    const assessment = await exam.__call("assessment");
    await addTask(factory, assessment.id, "Prove it", 10);
    const student = await factory.create("confirmed_user", []);
    await factory.create("assessment_participation", [], {
      assessment_id: assessment.id,
      user_id: student.id,
      status: "pending",
      submitted_at: new Date().toISOString(),
    });

    const page = new ExamDashboardPage(teacher.page, lecture.id);
    await openGrades(page);

    await expect(page.pane.getByText("Point entry in progress.")).toBeVisible();
    // the warning informs, it does not block — a teacher may configure early
    await expect(page.pane.getByRole("link", { name: "Create Grade Scheme" }))
      .toBeVisible();
  });

  test("keeps a student away from the grades tab", async ({
    factory,
    teacher,
    student,
  }) => {
    const { exam } = await markedExam(factory, teacher.user.id);

    await student.page.goto(`/exams/${exam.id}`);

    await expect(student.page.getByText("Create Grade Scheme")).toHaveCount(0);
    await expect(student.page.getByText("Configure Grade Scheme"))
      .toHaveCount(0);
  });
});
