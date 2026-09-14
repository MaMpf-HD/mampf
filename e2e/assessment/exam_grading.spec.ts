import { expect, test } from "../_support/fixtures";
import { ExamDashboardPage } from "../page-objects/exam_dashboard_page";
import { addTask, createLecture } from "./helpers";

/**
 * An exam is pointed task by task on its points tab and graded on its grades
 * tab; who did not turn up or brought a certificate is recorded there too.
 */
test.describe("exam grading", () => {
  async function examWithCandidates(factory: any, teacherId: number) {
    const lecture = await createLecture(factory, teacherId);
    const exam = await factory.create("exam", ["with_date"], {
      lecture_id: lecture.id,
      title: "Main Exam",
    });
    const assessment = await exam.__call("assessment");
    await addTask(factory, assessment.id, "Prove it", 10);
    for (const name of ["Ada Lovelace", "Grace Hopper"]) {
      const student = await factory.create("confirmed_user", [], { name_in_tutorials: name });
      await factory.create("exam_roster_entry", [], { exam_id: exam.id, user_id: student.id });
    }
    return { lecture, exam };
  }

  test("enters points and a grade, records an absence and an exemption", async ({
    factory,
    teacher,
  }) => {
    const { lecture } = await examWithCandidates(factory, teacher.user.id);
    const page = new ExamDashboardPage(teacher.page, lecture.id);
    await page.open("Main Exam");

    await page.tab("Points").click();
    await expect(page.pane.getByText("2 pending grading")).toBeVisible();
    const ada = page.pane.getByRole("row", { name: /Ada Lovelace/ });
    await ada.getByRole("spinbutton", { name: "Task 1 for Ada Lovelace" }).fill("7");
    await ada.getByRole("button", { name: "Save this row's points" }).click();
    await expect(ada.getByText("Reviewed")).toBeVisible();
    await expect(page.pane.getByText("1 reviewed · 1 pending grading")).toBeVisible();

    await page.tab("Grades").click();
    const adaGrade = page.pane.getByRole("row", { name: /Ada Lovelace/ });
    await expect(adaGrade.getByText("7.00")).toBeVisible();
    await adaGrade.getByRole("combobox", { name: "Grade for Ada Lovelace" }).selectOption("2.0");
    await adaGrade.getByRole("button", { name: "Save this row's grade" }).click();
    await expect(teacher.page.getByText("Changes saved.")).toBeVisible();
    await expect(adaGrade.getByText(/\d{4}-\d{2}-\d{2}, \d{2}:\d{2}/)).toHaveCount(0);
    await expect(adaGrade.getByRole("img", { name: /ago\)$/ })).toBeVisible();

    // points corrected after grading leave the grade, but not unnoticed
    await page.tab("Points").click();
    await ada.getByRole("spinbutton", { name: "Task 1 for Ada Lovelace" }).fill("9");
    await ada.getByRole("button", { name: "Save this row's points" }).click();
    await expect(page.pane.getByText("2 pending grading")).toBeHidden();
    await page.tab("Grades").click();
    await expect(adaGrade.getByRole("img", { name: /^Points changed on/ })).toBeVisible();
    await expect(page.pane.getByRole("alert")).toContainText("the points changed after the grade");
    await page.pane.getByRole("button", { name: "Show only these" }).click();
    await expect(page.pane.getByRole("row", { name: /Grace Hopper/ })).toBeHidden();
    await expect(adaGrade).toBeVisible();
    await page.pane.getByRole("button", { name: "Reset filters" }).click();

    // somebody who did not turn up gets no fields, and can be brought back
    const grace = page.pane.getByRole("row", { name: /Grace Hopper/ });
    await grace.getByRole("link", { name: "Record as absent" }).click();
    await expect(grace.getByRole("img", { name: "Absent" })).toBeVisible();
    await expect(grace.getByRole("combobox")).toHaveCount(0);
    await expect(page.pane.getByText("1 reviewed · 1 absent")).toBeVisible();
    await grace.getByRole("link", { name: "Take the absence back" }).click();
    await expect(grace.getByRole("combobox", { name: "Grade for Grace Hopper" })).toBeVisible();

    // a certificate excuses, with the reason kept for teaching staff
    await grace.getByRole("button", { name: "Excuse with a certificate" }).click();
    const dialog = teacher.page.getByRole("dialog");
    await dialog.getByLabel("Reason (optional, teaching staff only)").fill("sick note");
    await dialog.getByRole("button", { name: "Excuse" }).click();
    await expect(grace.getByRole("img", { name: "Exempt: sick note" })).toBeVisible();
    await expect(page.pane.getByText("1 reviewed · 1 exempt")).toBeVisible();
  });
});
