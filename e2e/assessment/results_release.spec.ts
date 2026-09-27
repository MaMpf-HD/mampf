import { expect, test } from "../_support/fixtures";
import { ExamDashboardPage } from "../page-objects/exam_dashboard_page";
import { addTask } from "./helpers";

test.describe("publishing results", () => {
  test("shows a student the exam result once published, and hides it once taken back", async ({
    factory,
    teacher,
    student,
  }) => {
    // the dashboard lists the lectures of the active term
    const term = await factory.create("term", ["summer", "active"], { year: 2025 });
    const lecture = await factory.create("lecture", ["released_for_all"], {
      teacher_id: teacher.user.id,
      term_id: term.id,
    });
    const exam = await factory.create("exam", ["with_date"], {
      lecture_id: lecture.id,
      title: "Main Exam",
    });
    const assessment = await exam.__call("assessment");
    await addTask(factory, assessment.id, "Prove it", 10);
    await factory.create("exam_roster_entry", [], { exam_id: exam.id, user_id: student.user.id });
    await factory.create("lecture_bookmark", [], { lecture_id: lecture.id, user_id: student.user.id });
    const name = student.user.name_in_tutorials || student.user.name;

    const dashboard = new ExamDashboardPage(teacher.page, lecture.id);
    await dashboard.open("Main Exam");
    await dashboard.tab("Points").click();
    const pointsRow = dashboard.pane.getByRole("row", { name });
    await pointsRow.getByRole("spinbutton", { name: `Task 1 for ${name}` }).fill("7");
    await pointsRow.getByRole("button", { name: "Save this row's points" }).click();
    await expect(pointsRow.getByText("Reviewed")).toBeVisible();

    await dashboard.tab("Grades").click();
    const gradeRow = dashboard.pane.getByRole("row", { name });
    await gradeRow.getByRole("combobox", { name: `Grade for ${name}` }).selectOption("2.0");
    await gradeRow.getByRole("button", { name: "Save this row's grade" }).click();
    await expect(teacher.page.getByText("Changes saved.")).toBeVisible();

    const pane = dashboard.pane;
    await expect(pane.getByText("Not published")).toBeVisible();
    await student.page.goto(`/lectures/${lecture.id}`);
    const examRow = student.page.getByTestId("participation-row").filter({ hasText: "Main Exam" });
    await expect(examRow).toContainText("On the exam list");
    await expect(examRow).not.toContainText("Grade 2.0");

    let question = "";
    teacher.page.once("dialog", (dialog) => {
      question = dialog.message();
      void dialog.accept();
    });
    await pane.getByRole("button", { name: "Publish results" }).click();
    await expect(pane.getByText(/Published \d/)).toBeVisible();
    expect(question).toContain("From now on, 1 person sees their result");

    await student.page.goto("/");
    await student.page.getByRole("link", { name: /Your result in Main Exam/ }).click();
    const block = student.page.getByRole("region", { name: "Your result in Main Exam" });
    await expect(block).toContainText("2.0");
    await expect(block).toContainText("7 of 10 points");
    await expect(block.getByRole("definition")).toHaveText("7 / 10");
    await expect(block.getByRole("term")).toHaveText("Prove it");

    await block.getByRole("button", { name: "Close" }).click();
    await expect(block).toBeHidden();
    await student.page.reload();
    await expect(block).toBeHidden();
    await expect(examRow).toContainText("Grade 2.0");
    await expect(examRow).toContainText("7 of 10 points");
    await examRow.getByText("Points per problem").click();
    await expect(examRow.getByRole("definition")).toHaveText("7 / 10");

    teacher.page.once("dialog", dialog => void dialog.accept());
    await pane.getByRole("button", { name: "Take back", exact: true }).click();
    await expect(pane.getByText("Not published")).toBeVisible();

    await student.page.reload();
    await expect(examRow).toContainText("On the exam list");
    await expect(examRow).not.toContainText("Grade 2.0");
  });

  test("publishes the talks that are graded, without the lecturer's note", async ({
    factory,
    teacher,
    student,
  }) => {
    const seminar = await factory.create("lecture", ["released_for_all", "is_seminar"], {
      teacher_id: teacher.user.id,
    });
    const other = await factory.create("confirmed_user", [], { name_in_tutorials: "Grace Hopper" });
    await factory.create("talk", [], {
      lecture_id: seminar.id, title: "Sylow theorems", speaker_ids: [student.user.id],
    });
    await factory.create("talk", [], {
      lecture_id: seminar.id, title: "Compilers", speaker_ids: [other.id],
    });
    const name = student.user.name_in_tutorials || student.user.name;

    await teacher.page.goto(`/lectures/${seminar.id}/edit?tab=assessments`);
    const row = teacher.page.getByRole("row", { name });
    await row.getByRole("combobox", { name: `Grade for ${name}` }).selectOption("1.3");
    await row.getByRole("textbox", { name: `Internal note on ${name}` })
      .fill("Rushed the last proof");
    await row.getByRole("button", { name: "Save this row's grade" }).click();
    await expect(row.getByText("Reviewed")).toBeVisible();

    // what is typed but not saved in another row survives publishing
    const graceRow = teacher.page.getByRole("row", { name: /Grace Hopper/ });
    const graceNote = graceRow.getByRole("textbox", { name: "Internal note on Grace Hopper" });
    await graceNote.fill("Draft, not saved");

    await expect(teacher.page.getByText("Not published")).toBeVisible();
    teacher.page.once("dialog", dialog => void dialog.accept());
    await teacher.page.getByRole("button", { name: "Publish 1 talk" }).click();
    await expect(teacher.page.getByText("1 of 2 published")).toBeVisible();
    await expect(row.getByRole("img", { name: "The speaker sees this grade" })).toBeVisible();
    await expect(graceRow.getByRole("img", { name: "The speaker sees this grade" }))
      .toHaveCount(0);
    await expect(graceNote).toHaveValue("Draft, not saved");

    await student.page.goto(`/lectures/${seminar.id}`);
    const talkRow = student.page.getByTestId("participation-row")
      .filter({ hasText: "Sylow theorems" });
    await expect(talkRow).toContainText("Grade 1.3");
    await expect(student.page.getByText("Rushed the last proof")).toHaveCount(0);
  });
});
