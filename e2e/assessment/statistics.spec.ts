import { expect, test } from "../_support/fixtures";
import { AssessmentDashboardPage } from "../page-objects/assessment_dashboard_page";
import { addTask, createAssessedAssignment, scoreTask } from "./helpers";

test.describe("the statistics of a sheet", () => {
  test("show how the points spread over the tasks and the programs", async ({
    factory,
    teacher,
  }) => {
    const { lecture, assignment, assessmentId } = await createAssessedAssignment(
      factory, teacher.user.id, "Problem Set 1", ["expired"],
    );
    const first = await addTask(factory, assessmentId, "Warm-up", 4);
    const second = await addTask(factory, assessmentId, "Proof", 6);
    const program = await factory.create("program", [], { degree: "msc" });
    const programName = await program.__call("name_with_subject");

    for (const [points, inProgram] of [[[4, 6], true], [[2, 0], true], [[4, 3], false]] as const) {
      const student = await factory.create("confirmed_user", [],
        inProgram ? { program_id: program.id } : {});
      const row = await factory.create("assessment_participation", [], {
        assessment_id: assessmentId, user_id: student.id,
        submitted_at: new Date(Date.now() - 2 * 86400000).toISOString(),
      });
      await scoreTask(factory, first.id, row.id, points[0]);
      await scoreTask(factory, second.id, row.id, points[1]);
      await row.update({ status: "reviewed", graded_at: new Date().toISOString() });
    }

    await teacher.page.goto(
      `/assessment/assessments/${assessmentId}`
      + `?assessable_type=Assignment&assessable_id=${assignment.id}&tab=statistics`,
    );
    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await expect(dashboard.tab("Statistics")).toHaveAttribute("aria-selected", "true");

    const tasks = teacher.page.getByRole("region", { name: "Tasks" });
    await expect(tasks.getByRole("row", { name: /Task 1/ })).toContainText("67%");
    await expect(tasks.getByRole("row", { name: /Task 2/ })).toContainText("50%");

    const programs = teacher.page.getByRole("region", { name: "By program" });
    await expect(programs.getByRole("row", { name: programName })
      .getByRole("cell", { name: "6", exact: true })).toHaveCount(2);
    await expect(programs.getByRole("row", { name: /Other or none given/ })).toBeVisible();
  });
});
