import { expect, test } from "../_support/fixtures";
import { AssessmentDashboardPage } from "../page-objects/assessment_dashboard_page";
import { addTask, createAssessedAssignment, createLegacyAssignment } from "./helpers";

/**
 * How a teacher gets around the assessment area: the tab that loads its
 * contents separately, the step from the list into one sheet, and the tabs
 * inside it. All of it is Turbo, so the server sees only fragments.
 */
test.describe("finding the way around the assessment area", () => {
  test("replaces the old assignments tab",
    async ({ factory, teacher }) => {
      const { lecture } = await createAssessedAssignment(factory, teacher.user.id);
      const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);

      await teacher.page.goto(`/lectures/${lecture.id}/edit`);
      await expect(teacher.page.getByRole("tab", { name: "Assessments" })).toBeVisible();
      await expect(teacher.page.getByRole("tab", { name: "Assignments" })).toHaveCount(0);

      await dashboard.gotoOverview();
      await expect(teacher.page.getByRole("link", { name: "Problem Set 1" }))
        .toBeVisible();
    });

  test("opens a sheet by clicking anywhere on its row", async ({
    factory,
    teacher,
  }) => {
    const { lecture } = await createAssessedAssignment(factory, teacher.user.id);

    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.gotoOverview();

    // not the link itself — the row around it
    await teacher.page.locator("tr", { hasText: "Problem Set 1" }).last()
      .getByRole("cell").last().click();

    await expect(dashboard.dashboard.getByRole("heading", { name: "Problem Set 1" }))
      .toBeVisible();
  });

  test("leaves a sheet from the old system alone", async ({
    factory,
    teacher,
  }) => {
    const { lecture } = await createLegacyAssignment(factory, teacher.user.id,
      "Ancient Sheet");

    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.gotoOverview();

    await expect(teacher.page.getByText("Assignments (legacy system without grading)"))
      .toBeVisible();

    // listed, but with no way into the new dashboard
    const row = teacher.page.locator(".assignmentRow", { hasText: "Ancient Sheet" });
    await expect(row).toBeVisible();
    await expect(teacher.page.getByRole("link", { name: "Ancient Sheet" }))
      .toHaveCount(0);

    await row.click();
    await expect(dashboard.dashboard).toHaveCount(0);
  });

  test("moves between the tabs of one sheet and stays where the save happened",
    async ({ factory, teacher }) => {
      const { lecture, assessmentId }
        = await createAssessedAssignment(factory, teacher.user.id);
      await addTask(factory, assessmentId, "Warm-up", 10);

      const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
      await dashboard.open("Problem Set 1");

      await expect(dashboard.tab("Settings")).toHaveAttribute("aria-selected", "true");
      await expect(dashboard.pane.getByLabel("Title")).toBeVisible();

      await dashboard.tab("Tasks").click();
      await expect(dashboard.taskCard("Warm-up")).toBeVisible();

      await dashboard.tab("Points").click();
      await expect(dashboard.pane.getByText("No points have been entered yet."))
        .toBeVisible();

      await dashboard.tab("Statistics").click();
      await expect(dashboard.pane.getByRole("heading", { name: "Submissions" }))
        .toBeVisible();
      await expect(dashboard.pane.getByText("Statistics are not yet available"))
        .toBeVisible();

      // saving from the settings tab must not drop the teacher somewhere else
      await dashboard.tab("Settings").click();
      await dashboard.pane.getByLabel("Title").fill("Problem Set 2");
      await dashboard.saveButton.click();

      await expect(teacher.page.getByText("Assessment updated successfully."))
        .toBeVisible();
      await expect(dashboard.tab("Settings")).toHaveAttribute("aria-selected", "true");
    });

  test("puts a task card back when its edit form is cancelled", async ({
    factory,
    teacher,
  }) => {
    const { lecture, assessmentId }
      = await createAssessedAssignment(factory, teacher.user.id);
    const task = await addTask(factory, assessmentId, "Warm-up", 10);

    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.open("Problem Set 1");
    await dashboard.tab("Tasks").click();

    const card = dashboard.pane.locator(`#assessment_task_${task.id}`);
    await card.getByRole("link", { name: "Edit" }).click();
    await expect(card.getByLabel("Max Points")).toBeVisible();

    await card.getByLabel("Max Points").fill("99");
    await card.getByRole("link", { name: "Cancel" }).click();

    await expect(card.getByLabel("Max Points")).toHaveCount(0);
    await expect(dashboard.taskCard("Warm-up")).toContainText("10 pts");
  });
});
