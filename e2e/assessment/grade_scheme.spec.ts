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
    await factory.create("exam_roster_entry", [], { exam_id: exam.id, user_id: student.id });
    const participation = await factory.create("assessment_participation", [], {
      assessment_id: assessment.id,
      user_id: student.id,
      status: "reviewed",
      submitted_at: new Date().toISOString(),
    });
    await scoreTask(factory, task.id, participation.id, 70);

    return { lecture, exam, task };
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
    await expect(page.pane.getByRole("button", { name: "Apply draft" }))
      .toBeVisible();
  });

  test("leaves the form without saving", async ({ factory, teacher }) => {
    const { lecture } = await markedExam(factory, teacher.user.id);

    const page = new ExamDashboardPage(teacher.page, lecture.id);
    await openGrades(page);
    await teacher.page.getByRole("link", { name: "Create Grade Scheme" })
      .click();
    await expect(page.pane.getByText("Configure Grade Scheme")).toBeVisible();

    await page.pane.getByRole("link", { name: "Cancel" }).click();

    await expect(page.pane.getByText("Configure Grade Scheme")).toHaveCount(0);
    await expect(page.pane.getByRole("link", { name: "Create Grade Scheme" }))
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
    // 70 of 100 points: the draft proposes 1.0 beside the empty grade, and
    // applying it writes the grade and drops the proposal
    const ada = page.pane.getByRole("row", { name: /Ada Lovelace/ });
    const proposal = ada.getByTitle("Proposal from the current grade scheme (not yet applied).");
    await expect(ada.getByRole("combobox", { name: "Grade for Ada Lovelace" })).toHaveValue("");
    await expect(proposal).toHaveText("1.0");
    await page.pane.getByRole("button", { name: "Apply draft" }).click();

    await expect(teacher.page.getByText("Grade scheme applied!")).toBeVisible();
    await expect(teacher.page.getByRole("link", { name: "Revise Scheme" }))
      .toBeVisible();
    await expect(ada.getByRole("combobox", { name: "Grade for Ada Lovelace" })).toHaveValue("1.0");
    await expect(proposal).toHaveCount(0);
  });

  // A scheme's grade follows the points it was computed from; a grade the
  // teacher typed is a decision and stays.
  test("brings its own grades up to corrected points, and leaves one entered by hand", async ({
    factory,
    teacher,
  }) => {
    const { lecture, exam, task } = await markedExam(factory, teacher.user.id);
    const assessment = await exam.__call("assessment");
    const grace = await factory.create("confirmed_user", [], { name_in_tutorials: "Grace Hopper" });
    await factory.create("exam_roster_entry", [], { exam_id: exam.id, user_id: grace.id });
    const graceRow = await factory.create("assessment_participation", [], {
      assessment_id: assessment.id, user_id: grace.id, status: "reviewed",
      submitted_at: new Date().toISOString(),
    });
    await scoreTask(factory, task.id, graceRow.id, 70);
    await factory.create("assessment_grade_scheme", [], { assessment_id: assessment.id });

    const page = new ExamDashboardPage(teacher.page, lecture.id);
    await openGrades(page);
    teacher.page.on("dialog", dialog => dialog.accept());
    await page.pane.getByRole("button", { name: "Apply draft" }).click();
    await expect(teacher.page.getByText("Grade scheme applied!")).toBeVisible();

    // Grace's 1.0 is overruled by hand
    const adaGrade = page.pane.getByRole("row", { name: /Ada Lovelace/ })
      .getByRole("combobox", { name: "Grade for Ada Lovelace" });
    const graceGrade = page.pane.getByRole("row", { name: /Grace Hopper/ })
      .getByRole("combobox", { name: "Grade for Grace Hopper" });
    await expect(adaGrade).toHaveValue("1.0");
    await graceGrade.selectOption("2.0");
    await page.pane.getByRole("row", { name: /Grace Hopper/ })
      .getByRole("button", { name: "Save this row's grade" }).click();
    await expect(teacher.page.getByText("Changes saved.")).toBeVisible();

    // both students' points are corrected down to 30
    await page.tab("Points").click();
    for (const name of ["Ada Lovelace", "Grace Hopper"]) {
      const row = page.pane.getByRole("row", { name: new RegExp(name) });
      await row.getByRole("spinbutton", { name: `Task 1 for ${name}` }).fill("30");
      const saved = teacher.page.waitForResponse(
        response => response.url().includes("/point_participation") && response.ok(),
      );
      await row.getByRole("button", { name: "Save this row's points" }).click();
      await saved;
    }

    // the scheme's grade follows, the hand's stays
    await page.tab("Grades").click();
    await expect(page.pane.getByText("1 grade from the scheme no longer fits the points."))
      .toBeVisible();
    await page.pane.getByRole("button", { name: /Apply to new and changed/ }).click();
    await expect(teacher.page.getByText("1 grade brought up to the changed points."))
      .toBeVisible();
    await expect(adaGrade).toHaveValue("3.0");
    await expect(graceGrade).toHaveValue("2.0");
    await expect(page.pane.getByRole("row", { name: /Grace Hopper/ })
      .getByRole("img", { name: /entered by hand/ })).toBeVisible();
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
    await page.pane.getByRole("button", { name: "Discard draft" }).click();

    await expect(teacher.page.getByText("Draft discarded.")).toBeVisible();
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
