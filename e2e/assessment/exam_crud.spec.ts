import { expect, test } from "../_support/fixtures";
import { ExamDashboardPage } from "../page-objects/exam_dashboard_page";
import { createLecture } from "./helpers";

/**
 * Exams are the second kind of assessable next to homework sheets: a scheduled
 * event with a room, a capacity and a date. They live on their own tab of the
 * lecture, and each one opens into the same dashboard the sheets use.
 */
test.describe("exams", () => {
  test("creates one and shows it in the list", async ({ factory, teacher }) => {
    const lecture = await createLecture(factory, teacher.user.id);

    const page = new ExamDashboardPage(teacher.page, lecture.id);
    await page.gotoList();
    await expect(teacher.page.getByText("No exams created yet.")).toBeVisible();

    await teacher.page.getByRole("link", { name: "Create New Exam" }).click();
    await page.container.getByLabel("Title").fill("Main Exam");
    await page.container.getByLabel("Location").fill("Lecture Hall 1");
    await page.container.getByRole("button", { name: "Save" }).click();

    await expect(teacher.page.getByText("Exam created successfully"))
      .toBeVisible();

    await page.gotoList();
    await expect(teacher.page.getByRole("link", { name: "Main Exam" }))
      .toBeVisible();
    await expect(teacher.page.getByRole("cell", { name: "Lecture Hall 1" }))
      .toBeVisible();
  });

  test("edits one and keeps the change", async ({ factory, teacher }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    await factory.create("exam", [], {
      lecture_id: lecture.id,
      title: "Main Exam",
      location: "Lecture Hall 1",
    });

    const page = new ExamDashboardPage(teacher.page, lecture.id);
    await page.open("Main Exam");
    await page.container.getByLabel("Location").fill("Lecture Hall 2");
    await page.container.getByRole("button", { name: "Save" }).click();

    await expect(teacher.page.getByText("Exam updated successfully"))
      .toBeVisible();

    await page.gotoList();
    await expect(teacher.page.getByRole("cell", { name: "Lecture Hall 2" }))
      .toBeVisible();
    await expect(teacher.page.getByRole("cell", { name: "Lecture Hall 1" }))
      .toHaveCount(0);
  });

  test("deletes one and leaves the list empty", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    await factory.create("exam", [], {
      lecture_id: lecture.id,
      title: "Main Exam",
    });

    const page = new ExamDashboardPage(teacher.page, lecture.id);
    await page.open("Main Exam");
    teacher.page.on("dialog", dialog => dialog.accept());
    await page.container.getByRole("button", { name: "Delete" }).click();

    await expect(teacher.page.getByText("Exam deleted successfully"))
      .toBeVisible();
    await expect(teacher.page.getByText("No exams created yet.")).toBeVisible();
  });

  test("moves between the dashboard tabs without leaving the page", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    await factory.create("exam", [], {
      lecture_id: lecture.id,
      title: "Main Exam",
    });

    const page = new ExamDashboardPage(teacher.page, lecture.id);
    await page.open("Main Exam");
    await expect(page.container.getByLabel("Title")).toBeVisible();

    await page.tab("Tasks").click();
    await expect(page.container.getByLabel("Title")).toBeHidden();

    await page.tab("Settings").click();
    await expect(page.container.getByLabel("Title")).toBeVisible();
    await expect(page.container.getByLabel("Title")).toHaveValue("Main Exam");
    await expect(teacher.page).toHaveURL(/tab=exams/);
  });

  test("warns while an edit is unsaved", async ({ factory, teacher }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    await factory.create("exam", [], {
      lecture_id: lecture.id,
      title: "Main Exam",
    });

    const page = new ExamDashboardPage(teacher.page, lecture.id);
    await page.open("Main Exam");
    await page.container.getByLabel("Title").fill("Retake Exam");

    await expect(page.pane.getByText("Attention, there are unsaved changes!"))
      .toBeVisible();
  });

  test("adds somebody to the participants by email", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    await factory.create("exam", ["with_date"], {
      lecture_id: lecture.id,
      title: "Main Exam",
      skip_campaigns: true,
    });
    const candidate = await factory.create("confirmed_user", [], {
      name_in_tutorials: "Ada Lovelace",
    });

    const page = new ExamDashboardPage(teacher.page, lecture.id);
    await page.open("Main Exam");
    await page.tab("Roster").click();
    await page.pane.getByRole("button", { name: "Add person by email" })
      .click();
    await page.pane.getByLabel("Add person by email").fill(candidate.email);
    await page.pane.getByRole("button", { name: "Add", exact: true }).click();

    await expect(teacher.page.getByText("Ada Lovelace has been added."))
      .toBeVisible();
    await expect(page.pane.getByRole("cell", { name: "Ada Lovelace" }))
      .toBeVisible();
  });

  test("removes somebody from the participants again", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    const exam = await factory.create("exam", ["with_date"], {
      lecture_id: lecture.id,
      title: "Main Exam",
      skip_campaigns: true,
    });
    const participant = await factory.create("confirmed_user", [], {
      name_in_tutorials: "Ada Lovelace",
    });
    await factory.create("exam_roster_entry", [], {
      exam_id: exam.id,
      user_id: participant.id,
    });

    const page = new ExamDashboardPage(teacher.page, lecture.id);
    await page.open("Main Exam");
    await page.tab("Roster").click();
    await expect(page.pane.getByRole("cell", { name: "Ada Lovelace" }))
      .toBeVisible();

    teacher.page.on("dialog", dialog => dialog.accept());
    await page.pane.getByRole("button", { name: "Remove" }).first().click();

    await expect(teacher.page.getByText("Ada Lovelace has been removed."))
      .toBeVisible();
    await expect(page.pane.getByRole("cell", { name: "Ada Lovelace" }))
      .toHaveCount(0);
  });

  test("sends a direct visit to the lecture's exam tab", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    const exam = await factory.create("exam", [], {
      lecture_id: lecture.id,
      title: "Main Exam",
    });

    await teacher.page.goto(`/exams/${exam.id}`);

    await expect(teacher.page).toHaveURL(
      new RegExp(`/lectures/${lecture.id}/edit\\?tab=exams`),
    );
    await expect(teacher.page.getByRole("link", { name: "Main Exam" }))
      .toBeVisible();
  });

  test("keeps a student out of somebody else's exam", async ({
    factory,
    teacher,
    student,
  }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    const exam = await factory.create("exam", [], {
      lecture_id: lecture.id,
      title: "Main Exam",
    });

    await student.page.goto(`/exams/${exam.id}`);

    await expect(student.page.getByRole("link", { name: "Main Exam" }))
      .toHaveCount(0);
  });
});
