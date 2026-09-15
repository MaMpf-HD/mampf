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

    // the scheme card on the grades tab counts along
    await page.tab("Grades").click();
    await expect(page.pane.getByText("1 of 2 reviewed, 1 still pending.")).toBeVisible();
    await page.tab("Points").click();

    await page.tab("Grades").click();
    const adaGrade = page.pane.getByRole("row", { name: /Ada Lovelace/ });
    await expect(adaGrade.getByText("7.00")).toBeVisible();
    await adaGrade.getByRole("combobox", { name: "Grade for Ada Lovelace" }).selectOption("2.0");
    await adaGrade.getByRole("button", { name: "Save this row's grade" }).click();
    await expect(teacher.page.getByText("Changes saved.")).toBeVisible();
    await expect(adaGrade.getByRole("img", { name: /^Reviewed: .* ago\)$/ })).toBeVisible();

    // points corrected after grading leave the grade, but not unnoticed
    await page.tab("Points").click();
    await ada.getByRole("spinbutton", { name: "Task 1 for Ada Lovelace" }).fill("9");
    const corrected = teacher.page.waitForResponse(
      response => response.url().includes("/point_participation") && response.ok(),
    );
    await ada.getByRole("button", { name: "Save this row's points" }).click();
    await corrected;
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

    // a certificate excuses, with the reason kept for teaching staff; the
    // dialog hands the keyboard back to the row it came from
    const excuse = grace.getByRole("button", { name: "Excuse with a certificate" });
    await excuse.focus();
    await teacher.page.keyboard.press("Enter");
    const dialog = teacher.page.getByRole("dialog", { name: "Excuse from the exam" });
    await dialog.getByRole("button", { name: "Cancel" }).click();
    await expect(excuse).toBeFocused();
    await excuse.click();
    await dialog.getByLabel("Reason (optional, teaching staff only)").fill("sick note");
    await dialog.getByRole("button", { name: "Excuse" }).click();
    await expect(grace.getByRole("img", { name: "Exempt: sick note" })).toBeVisible();
    await expect(page.pane.getByText("1 reviewed · 1 exempt")).toBeVisible();
    await expect(grace.getByRole("link", { name: "Take the exemption back" })).toBeFocused();

    // excused while the filter shows the pending only, the row disappears
    // and the keyboard lands on the filter instead of nowhere
    await grace.getByRole("link", { name: "Take the exemption back" }).click();
    await expect(grace.getByRole("combobox", { name: "Grade for Grace Hopper" })).toBeVisible();
    await page.pane.getByLabel("Status").selectOption("pending_grading");
    await expect(adaGrade).toBeHidden();
    await grace.getByRole("button", { name: "Excuse with a certificate" }).click();
    await dialog.getByRole("button", { name: "Excuse" }).click();
    await expect(grace).toBeHidden();
    await expect(page.pane.getByLabel("Name")).toBeFocused();
  });

  test("shows 20 candidates at a time, or one tutorial's", async ({ factory, teacher }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    const exam = await factory.create("exam", ["with_date"], {
      lecture_id: lecture.id,
      title: "Main Exam",
    });
    const tutorial = await factory.create("tutorial", [], {
      lecture_id: lecture.id,
      title: "Group A",
    });
    for (let index = 1; index <= 26; index++) {
      const student = await factory.create("confirmed_user", [], {
        name_in_tutorials: `Candidate ${index}`,
      });
      await factory.create("exam_roster_entry", [], { exam_id: exam.id, user_id: student.id });
      if (index === 26) {
        await factory.create("tutorial_membership", [], {
          tutorial_id: tutorial.id,
          user_id: student.id,
        });
      }
    }
    const page = new ExamDashboardPage(teacher.page, lecture.id);
    await page.open("Main Exam");
    await page.tab("Grades").click();

    // the page is turned above the table and below it
    const candidates = page.pane.getByRole("row", { name: /Candidate/ });
    await expect(candidates.filter({ visible: true })).toHaveCount(20);
    await expect(page.pane.getByText("Rows 1–20 of 26")).toHaveCount(2);
    await page.pane.getByRole("button", { name: "Next" }).last().click();
    await expect(candidates.filter({ visible: true })).toHaveCount(6);
    await expect(page.pane.getByText("Rows 21–26 of 26").first()).toBeVisible();

    // the size chosen on one tab holds on the other
    await page.pane.getByLabel("Per page").selectOption("50");
    await expect(candidates.filter({ visible: true })).toHaveCount(26);
    await expect(page.pane.getByText("Rows 1–26 of 26").first()).toBeVisible();
    await page.tab("Points").click();
    await expect(page.pane.getByRole("row", { name: /Candidate/ }).filter({ visible: true }))
      .toHaveCount(26);
    await page.tab("Grades").click();

    await page.pane.getByLabel("Tutorial").selectOption("Group A");
    await expect(candidates.filter({ visible: true })).toHaveCount(1);
    await expect(page.pane.getByRole("row", { name: /Candidate 26/ })).toBeVisible();
    await expect(page.pane.getByText("Rows 1–26 of 26")).toHaveCount(0);
  });
});
