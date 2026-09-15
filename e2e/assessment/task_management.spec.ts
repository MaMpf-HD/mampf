import { expect, test } from "../_support/fixtures";
import { AssessmentDashboardPage } from "../page-objects/assessment_dashboard_page";
import { addTask, createAssessedAssignment } from "./helpers";

const PRECISION_WARNING = "Only 2 decimal places are stored.";

/**
 * Two browser-only behaviours on the tasks tab: the warning that points are
 * rounded, and dragging a task to a new place. Both talk to the server only
 * afterwards, if at all, so a request spec sees neither.
 */
test.describe("assessment tasks", () => {
  test("warns while more than two decimal places are typed", async ({
    factory,
    teacher,
  }) => {
    const { lecture, assessmentId }
      = await createAssessedAssignment(factory, teacher.user.id);
    const task = await addTask(factory, assessmentId, "Warm-up", 10);

    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.open("Problem Set 1");
    await dashboard.tab("Tasks").click();

    const newTaskPoints = dashboard.pane.getByLabel("Max Points");
    const newTaskWarning = dashboard.pane.getByText(PRECISION_WARNING);
    await expect(newTaskWarning).toBeHidden();

    await newTaskPoints.fill("0.125");
    await expect(newTaskWarning).toBeVisible();

    await newTaskPoints.fill("0.12");
    await expect(newTaskWarning).toBeHidden();

    await newTaskPoints.fill("0.125");
    await expect(newTaskWarning).toBeVisible();
    await newTaskPoints.fill("");
    await expect(newTaskWarning).toBeHidden();

    // the edit form carries its own copy of the controller, and its own field
    // ids — reachable by label only because the form is namespaced
    await dashboard.taskCard("Warm-up").getByRole("link", { name: "Edit" }).click();
    const editForm = dashboard.pane.locator(`#assessment_task_${task.id}`);
    const editWarning = editForm.getByText(PRECISION_WARNING);
    await expect(editWarning).toBeHidden();

    await editForm.getByLabel("Max Points").fill("7.5555");
    await expect(editWarning).toBeVisible();
  });

  test("saves a new task order when a task is dragged", async ({
    factory,
    teacher,
  }) => {
    const { lecture, assessmentId }
      = await createAssessedAssignment(factory, teacher.user.id);
    await addTask(factory, assessmentId, "First", 10);
    await addTask(factory, assessmentId, "Second", 10);
    await addTask(factory, assessmentId, "Third", 10);

    let reorderRequests = 0;
    teacher.page.on("request", (request) => {
      if (request.url().includes("/tasks/reorder")) {
        reorderRequests += 1;
      }
    });

    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.open("Problem Set 1");
    await dashboard.tab("Tasks").click();

    await expect(dashboard.tasks).toHaveText([/First/, /Second/, /Third/]);

    const reorder = teacher.page.waitForResponse(
      response => response.url().includes("/tasks/reorder"),
    );
    await dashboard.dragTaskAbove("Third", "First");
    await reorder;

    await expect(dashboard.tasks).toHaveText([/Third/, /First/, /Second/]);
    await expect(dashboard.taskPositions).toHaveText(["1.", "2.", "3."]);
    expect(reorderRequests).toBe(1);

    await dashboard.open("Problem Set 1");
    await dashboard.tab("Tasks").click();
    await expect(dashboard.tasks).toHaveText([/Third/, /First/, /Second/]);
  });

  test("takes a dragged task back when the new order cannot be saved", async ({
    factory,
    teacher,
  }) => {
    const { lecture, assessmentId }
      = await createAssessedAssignment(factory, teacher.user.id);
    await addTask(factory, assessmentId, "First", 10);
    await addTask(factory, assessmentId, "Second", 10);

    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.open("Problem Set 1");
    await dashboard.tab("Tasks").click();
    await expect(dashboard.tasks).toHaveText([/First/, /Second/]);

    await teacher.page.route("**/tasks/reorder", route => route.abort());
    await dashboard.dragTaskAbove("Second", "First");

    await expect(teacher.page.getByText("The new order could not be saved."))
      .toBeVisible();
    await expect(dashboard.tasks).toHaveText([/First/, /Second/]);
    await expect(dashboard.taskPositions).toHaveText(["1.", "2."]);
  });

  test("edits a task and keeps the change", async ({ factory, teacher }) => {
    const { lecture, assessmentId }
      = await createAssessedAssignment(factory, teacher.user.id);
    const task = await addTask(factory, assessmentId, "Warm-up", 10);

    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.open("Problem Set 1");
    await dashboard.tab("Tasks").click();

    await dashboard.taskCard("Warm-up").getByRole("link", { name: "Edit" }).click();
    const editForm = dashboard.pane.locator(`#assessment_task_${task.id}`);
    await editForm.getByLabel("Max Points").fill("15");
    await editForm.getByLabel("Task name").fill("Warm-up, revised");
    await editForm.getByRole("button", { name: "Save" }).click();

    await expect(dashboard.tasks).toHaveText([/15 pts.*Warm-up, revised/s]);

    await dashboard.open("Problem Set 1");
    await dashboard.tab("Tasks").click();
    await expect(dashboard.tasks).toHaveText([/15 pts.*Warm-up, revised/s]);
  });

  test("deletes a task and renumbers what is left", async ({ factory, teacher }) => {
    const { lecture, assessmentId }
      = await createAssessedAssignment(factory, teacher.user.id);
    await addTask(factory, assessmentId, "First", 10);
    await addTask(factory, assessmentId, "Second", 10);

    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.open("Problem Set 1");
    await dashboard.tab("Tasks").click();

    teacher.page.on("dialog", dialog => dialog.accept());
    await dashboard.taskCard("First").getByRole("button", { name: "Delete" }).click();

    await expect(dashboard.tasks).toHaveText([/Second/]);
    await expect(dashboard.taskPositions).toHaveText(["1."]);
  });

  test("adds a task and stays on the tasks tab", async ({ factory, teacher }) => {
    const { lecture } = await createAssessedAssignment(factory, teacher.user.id);

    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.open("Problem Set 1");
    await dashboard.tab("Tasks").click();

    await dashboard.pane.getByLabel("Max Points").fill("12");
    await dashboard.pane.getByRole("button", { name: "Add Task" }).click();

    await expect(dashboard.tasks).toHaveText([/12 pts/]);
    await expect(dashboard.tab("Tasks")).toHaveAttribute("aria-selected", "true");
  });
});
