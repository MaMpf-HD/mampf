import { expect, test } from "../_support/fixtures";
import { AssessmentDashboardPage } from "../page-objects/assessment_dashboard_page";
import { addTask, createAssessedAssignment, markSomebody, scoreTask } from "./helpers";

/**
 * What the interface refuses to do, and what it says when there is nothing to
 * show. Both are decided in the template, so the server has no opinion on
 * either — a locked control still answers a POST.
 */
test.describe("guards and empty states", () => {
  test("locks the submission fields once the deadline has passed", async ({
    factory,
    teacher,
  }) => {
    const { lecture } = await createAssessedAssignment(
      factory, teacher.user.id, "Problem Set 1", ["expired"],
    );

    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.open("Problem Set 1");

    await expect(dashboard.pane.getByLabel("Submission format")).toBeDisabled();
    await expect(dashboard.pane.getByRole("checkbox", {
      name: "Requires digital submission",
    })).toBeDisabled();
    await expect(dashboard.pane.getByText("Locked (deadline has passed)").first())
      .toBeVisible();

    // the title stays editable — only the submission side is frozen
    await expect(dashboard.pane.getByLabel("Title")).toBeEditable();
  });

  test("leaves the submission fields alone while the deadline is running",
    async ({ factory, teacher }) => {
      const { lecture } = await createAssessedAssignment(factory, teacher.user.id);

      const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
      await dashboard.open("Problem Set 1");

      await expect(dashboard.pane.getByLabel("Submission format")).toBeEnabled();
      await expect(dashboard.pane.getByText("Locked (deadline has passed)"))
        .toHaveCount(0);
    });

  test("refuses to delete a task somebody has already been scored on", async ({
    factory,
    teacher,
  }) => {
    const { lecture, assessmentId } = await createAssessedAssignment(
      factory, teacher.user.id, "Problem Set 1", ["expired"],
    );
    const task = await addTask(factory, assessmentId, "Warm-up", 10);
    const participation = await markSomebody(factory, assessmentId);
    await scoreTask(factory, task.id, participation.id, 7);

    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.open("Problem Set 1");
    await dashboard.tab("Tasks").click();

    const card = dashboard.taskCard("Warm-up");
    await expect(card.getByRole("button", { name: "Delete" })).toBeDisabled();
    await expect(card.getByTitle(
      "Cannot delete: Points have been entered for this task.",
    )).toBeVisible();
  });

  test("keeps the task when the confirmation is declined", async ({
    factory,
    teacher,
  }) => {
    const { lecture, assessmentId }
      = await createAssessedAssignment(factory, teacher.user.id);
    await addTask(factory, assessmentId, "Warm-up", 10);

    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.open("Problem Set 1");
    await dashboard.tab("Tasks").click();

    teacher.page.on("dialog", dialog => dialog.dismiss());
    await dashboard.taskCard("Warm-up").getByRole("button", { name: "Delete" })
      .click();

    await expect(dashboard.taskCard("Warm-up")).toBeVisible();
    await expect(dashboard.tasks).toHaveCount(1);
  });

  test("says so when a lecture has no sheets and a sheet has no tasks", async ({
    factory,
    teacher,
  }) => {
    const empty = await factory.create("lecture", ["released_for_all"], {
      teacher_id: teacher.user.id,
      locale: "en",
    });

    const emptyLecture = new AssessmentDashboardPage(teacher.page, empty.id);
    await emptyLecture.gotoOverview();
    await expect(teacher.page.getByText("No assignments created yet."))
      .toBeVisible();

    const { lecture } = await createAssessedAssignment(factory, teacher.user.id);
    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.open("Problem Set 1");
    await dashboard.tab("Tasks").click();

    await expect(dashboard.pane.getByText("No tasks created yet.")).toBeVisible();
  });
});
