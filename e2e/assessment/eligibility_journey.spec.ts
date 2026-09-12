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
    // Nothing is proposed while sheets can still be added, and creating one
    // opens the list again - so it is closed once the sheet is there.
    await lecture.update({ assignments_complete: true });

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
    // "Eligible" is a substring of "Not Eligible", so the verdict has to be
    // pinned from both sides.
    await expect(decision).toContainText("Eligible");
    await expect(decision).not.toContainText("Not Eligible");
  });

  test("moves the recorded decisions when the rule is tightened", async ({
    factory,
    teacher,
  }) => {
    // Nothing is proposed while the lecture may still add sheets.
    const lecture = await createEligibilityLecture(
      factory, teacher.user.id, { assignments_complete: true },
    );
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
    // A decided row carries the inline editor with it, and that lists both
    // verdicts - so the row's own text says nothing. The decision as displayed
    // is the first of the two `display` blocks in the row; read whole, it can
    // only be one verdict.
    const verdict = (name: RegExp) =>
      teacher.page.getByRole("row", { name })
        .locator("[data-certification-inline-target='display']").first();

    const ada = teacher.page.getByRole("row", { name: /Ada Lovelace/ });
    await expect(ada).not.toContainText("Proposed");
    await expect(verdict(/Ada Lovelace/)).toHaveText("Eligible");
    await expect(verdict(/Grace Hopper/)).toHaveText("Not Eligible");

    await teacher.page.getByRole("link", { name: "Edit Rule" }).click();
    await teacher.page.getByRole("radio", { name: "Percentage of total points" })
      .check();
    await teacher.page.getByLabel("Minimum percentage").fill("70");
    await teacher.page.getByRole("button", { name: "Save Rule" }).click();

    await expect(teacher.page.getByText(/Eligibility rule updated/))
      .toBeVisible();
    await teacher.page
      .getByRole("button", { name: "Reconcile with rule" }).click();

    // the row says "Not Eligible" either way — once as the rule's objection,
    // once as the decision. What only reconciling does is settle the argument.
    const reconciled = teacher.page.getByRole("row", { name: /Ada Lovelace/ });
    await expect(reconciled).not.toContainText("Per rule:");
    await expect(verdict(/Ada Lovelace/)).toHaveText("Not Eligible");
    // And the page stops asking: nothing contradicts the rule any more.
    await expect(teacher.page.getByRole("button", { name: "Reconcile with rule" }))
      .toHaveCount(0);
  });
});
