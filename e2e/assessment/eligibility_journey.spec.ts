import { enableFeature } from "../_support/backend";
import { expect, test } from "../_support/fixtures";
import { AssessmentDashboardPage } from "../page-objects/assessment_dashboard_page";
import { addTask, createEligibilityLecture, scoreTask } from "./helpers";

/**
 * The paths that cross the areas. Each one starts where a fact is recorded and
 * ends where a person decides on it, which is the whole point of the feature —
 * and it is the only place where the callbacks between assessments, records and
 * the evaluator are exercised together.
 *
 * Marking itself is not clickable in these slices, so the mark is made through
 * the factory; everything the teacher does afterwards goes through the screen.
 */
test.describe("from a mark to a decision", () => {
  test.beforeEach(async ({ request }) => {
    await enableFeature(request, "assessment_grading");
    await enableFeature(request, "student_performance");
  });

  test("carries a fresh mark through to the eligibility proposal", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createEligibilityLecture(factory, teacher.user.id);
    const assignment = await factory.create("assignment", ["expired"], {
      lecture_id: lecture.id,
      title: "Problem Set 1",
    });
    const assessment = await assignment.__call("assessment");
    const task = await addTask(factory, assessment.id, "Prove it", 10);
    await factory.create("student_performance_rule", ["active"], {
      lecture_id: lecture.id,
      threshold_mode: "percentage",
      min_percentage: 50,
    });

    const member = await factory.create("confirmed_user", [], {
      name_in_tutorials: "Ada Lovelace",
    });
    await factory.create("lecture_membership", [], {
      lecture_id: lecture.id,
      user_id: member.id,
    });

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await page.gotoOverview();
    await page.overviewTab("Performance").click();
    const before = teacher.page.getByRole("row", { name: /Ada Lovelace/ });
    await expect(before).toContainText("0");

    // somebody marks the sheet — the record is recomputed by a callback
    const participation = await factory.create("assessment_participation", [], {
      assessment_id: assessment.id,
      user_id: member.id,
      status: "reviewed",
      submitted_at: new Date().toISOString(),
    });
    await scoreTask(factory, task.id, participation.id, 7);

    await page.gotoOverview();
    await page.overviewTab("Performance").click();
    const after = teacher.page.getByRole("row", { name: /Ada Lovelace/ });
    await expect(after).toContainText("7");
    await expect(after).toContainText("70");

    await page.gotoOverview();
    await page.overviewTab("Exam Eligibility").click();
    const decision = teacher.page.getByRole("row", { name: /Ada Lovelace/ });
    await expect(decision).toContainText("Proposed");
    await expect(decision).toContainText("Eligible");
  });

  test("moves the recorded decisions when the rule is tightened", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createEligibilityLecture(factory, teacher.user.id);
    await factory.create("student_performance_rule", ["active"], {
      lecture_id: lecture.id,
      threshold_mode: "percentage",
      min_percentage: 50,
    });
    for (const [name, percentage] of [["Ada Lovelace", 60],
                                      ["Grace Hopper", 40]] as const) {
      const user = await factory.create("confirmed_user", [], {
        name_in_tutorials: name,
      });
      await factory.create("student_performance_record", [], {
        lecture_id: lecture.id,
        user_id: user.id,
        points_total_materialized: percentage,
        points_max_materialized: 100,
        percentage_materialized: percentage,
      });
    }

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await page.gotoOverview();
    await page.overviewTab("Exam Eligibility").click();

    await teacher.page.getByRole("button", { name: "Accept Open Proposals" })
      .click();
    // the row already said "Eligible" as a proposal, so what marks the swap is
    // that it stopped being one
    const ada = teacher.page.getByRole("row", { name: /Ada Lovelace/ });
    await expect(ada).not.toContainText("Proposed");
    await expect(ada).toContainText("Eligible");
    await expect(teacher.page.getByRole("row", { name: /Grace Hopper/ }))
      .toContainText("Not Eligible");

    await teacher.page.getByRole("link", { name: "Edit Rule" }).click();
    await teacher.page.getByRole("radio", { name: "Percentage of total points" })
      .check();
    await teacher.page.getByLabel("Minimum percentage").fill("70");
    await teacher.page.getByRole("button", { name: "Save Rule" }).click();

    await expect(teacher.page.getByText(/Eligibility rule changed/))
      .toBeVisible();
    await teacher.page
      .getByRole("button", { name: "Reconcile with current rule" }).click();

    // the row says "Not Eligible" either way — once as the rule's objection,
    // once as the decision. What only reconciling does is settle the argument.
    const reconciled = teacher.page.getByRole("row", { name: /Ada Lovelace/ });
    await expect(reconciled).not.toContainText("Per rule:");
    await expect(reconciled).toContainText("Not Eligible");
    await expect(teacher.page.getByText(/Eligibility rule changed/))
      .toHaveCount(0);
  });
});
