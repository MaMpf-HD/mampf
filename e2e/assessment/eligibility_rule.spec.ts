import { enableFeature } from "../_support/backend";
import { expect, test } from "../_support/fixtures";
import { AssessmentDashboardPage } from "../page-objects/assessment_dashboard_page";
import { createEligibilityLecture } from "./helpers";

/**
 * The rule that decides who may sit the exam: a point threshold, a set of
 * achievements, or both. It is edited in place on the eligibility tab, and it
 * is the one place where achievements and points come together.
 */
test.describe("the eligibility rule", () => {
  test.beforeEach(async ({ request }) => {
    await enableFeature(request, "assessment_grading");
    await enableFeature(request, "student_performance");
  });

  async function openEligibility(page: AssessmentDashboardPage) {
    await page.gotoOverview();
    await page.overviewTab("Exam Eligibility").click();
  }

  test("is missing until a teacher sets one up", async ({ factory, teacher }) => {
    const lecture = await createEligibilityLecture(factory, teacher.user.id);

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await openEligibility(page);

    await expect(teacher.page.getByText("No active eligibility rule configured"))
      .toBeVisible();
    await expect(teacher.page.getByRole("link", { name: "Set up rule" }))
      .toBeVisible();
  });

  test("records a percentage of the total points", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createEligibilityLecture(factory, teacher.user.id);

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await openEligibility(page);
    await teacher.page.getByRole("link", { name: "Set up rule" }).click();

    await teacher.page.getByRole("radio", { name: "Percentage of total points" })
      .check();
    await teacher.page.getByLabel("Minimum percentage").fill("60");
    await teacher.page.getByRole("button", { name: "Save Rule" }).click();

    await expect(teacher.page.getByText("Eligibility rule updated.")).toBeVisible();
    const summary = teacher.page.locator("#rule-editor-frame");
    await expect(summary.getByText("of total points required")).toBeVisible();
    await expect(summary.getByText("60%")).toBeVisible();

    // and it does not turn up again somewhere unrelated
    await teacher.page.goto("/main/start");
    await expect(teacher.page.getByText("Eligibility rule updated."))
      .toHaveCount(0);
  });

  test("changes a percentage rule into an absolute one", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createEligibilityLecture(factory, teacher.user.id);
    await factory.create("student_performance_rule", ["active"], {
      lecture_id: lecture.id,
      threshold_mode: "percentage",
      min_percentage: 60,
    });

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await openEligibility(page);
    await teacher.page.getByRole("link", { name: "Edit Rule" }).click();

    await teacher.page.getByRole("radio", { name: "Absolute points" }).check();
    await teacher.page.getByLabel("Minimum points").fill("45");
    await teacher.page.getByRole("button", { name: "Save Rule" }).click();

    await expect(teacher.page.getByText("points required (absolute)"))
      .toBeVisible();
    await expect(teacher.page.getByText("of total points required"))
      .toHaveCount(0);
  });

  test("demands an achievement alongside the points", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createEligibilityLecture(factory, teacher.user.id);
    await factory.create("achievement", ["boolean"], {
      lecture_id: lecture.id,
      title: "Blackboard talk",
    });

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await openEligibility(page);
    await teacher.page.getByRole("link", { name: "Set up rule" }).click();

    await teacher.page.getByRole("radio", { name: "Percentage of total points" })
      .check();
    await teacher.page.getByLabel("Minimum percentage").fill("50");
    await teacher.page.getByRole("checkbox", { name: "Blackboard talk" }).check();
    await teacher.page.getByRole("button", { name: "Save Rule" }).click();

    const summary = teacher.page.locator("#rule-editor-frame");
    await expect(summary.getByText("Achievements")).toBeVisible();
    await expect(summary.getByText("Blackboard talk")).toBeVisible();
  });

  test("shows the field that belongs to the chosen kind of threshold", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createEligibilityLecture(factory, teacher.user.id);

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await openEligibility(page);
    await teacher.page.getByRole("link", { name: "Set up rule" }).click();

    const percent = teacher.page.getByLabel("Minimum percentage");
    const points = teacher.page.getByLabel("Minimum points");

    await teacher.page.getByRole("radio", { name: "Percentage of total points" })
      .check();
    await expect(percent).toBeVisible();
    await expect(points).toBeHidden();

    await teacher.page.getByRole("radio", { name: "Absolute points" }).check();
    await expect(points).toBeVisible();
    await expect(percent).toBeHidden();

    await teacher.page.getByRole("radio", { name: "No point threshold" }).check();
    await expect(percent).toBeHidden();
    await expect(points).toBeHidden();
  });

  test("opens an existing rule on the field it was saved with", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createEligibilityLecture(factory, teacher.user.id);
    await factory.create("student_performance_rule", ["active"], {
      lecture_id: lecture.id,
      threshold_mode: "absolute",
      min_percentage: null,
      min_points_absolute: 45,
    });

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await openEligibility(page);
    await teacher.page.getByRole("link", { name: "Edit Rule" }).click();

    await expect(teacher.page.getByLabel("Minimum points")).toHaveValue("45.0");
    await expect(teacher.page.getByLabel("Minimum percentage")).toBeHidden();
  });

  test("refuses a rule that would let everyone through", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createEligibilityLecture(factory, teacher.user.id);
    await factory.create("achievement", ["boolean"], {
      lecture_id: lecture.id,
      title: "Blackboard talk",
    });

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await openEligibility(page);
    await teacher.page.getByRole("link", { name: "Set up rule" }).click();

    // no threshold and no achievement is not an empty rule, it is a rule that
    // certifies the whole lecture
    await teacher.page.getByRole("radio", { name: "No point threshold" }).check();
    await teacher.page.getByRole("button", { name: "Save Rule" }).click();

    await expect(teacher.page.getByText(
      "The rule needs at least one criterion",
    )).toBeVisible();
    await expect(teacher.page.getByText("No active eligibility rule configured"))
      .toHaveCount(0);
    expect(await lecture.__call("student_performance_rules")).toHaveLength(0);
  });

  test("says who would change status before the rule is saved", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createEligibilityLecture(factory, teacher.user.id);
    await factory.create("student_performance_rule", ["active"], {
      lecture_id: lecture.id,
      threshold_mode: "percentage",
      min_percentage: 50,
    });
    // one comfortably above the current bar, one just below a stricter one
    for (const percentage of [40, 60]) {
      await factory.create("student_performance_record", [], {
        lecture_id: lecture.id,
        points_total_materialized: percentage,
        points_max_materialized: 100,
        percentage_materialized: percentage,
      });
    }

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await openEligibility(page);
    await teacher.page.getByRole("link", { name: "Edit Rule" }).click();

    await teacher.page.getByLabel("Minimum percentage").fill("70");
    await teacher.page.getByRole("button", { name: "Preview" }).click();

    await expect(teacher.page.getByText("Impact")).toBeVisible();
    await expect(teacher.page.getByText("newly ineligible")).toBeVisible();

    // and it names them, not just counts them
    const preview = teacher.page.locator("#rule-preview-frame");
    await expect(preview.getByRole("columnheader", { name: "With new rule" }))
      .toBeVisible();
    await expect(preview.locator("tbody tr")).toHaveCount(1);

    // "deferred" moves in both directions, which needs saying
    await expect(preview.getByText("Deferred means the case is still open"))
      .toBeVisible();

    // a preview changes nothing on record
    const rules = await lecture.__call("student_performance_rules");
    expect(rules[0].min_percentage).toBe("50.0");
  });

  test("leaves the rule alone when the editor is cancelled", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createEligibilityLecture(factory, teacher.user.id);
    await factory.create("student_performance_rule", ["active"], {
      lecture_id: lecture.id,
      threshold_mode: "percentage",
      min_percentage: 60,
    });

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await openEligibility(page);
    await teacher.page.getByRole("link", { name: "Edit Rule" }).click();

    await teacher.page.getByLabel("Minimum percentage").fill("90");
    await teacher.page.getByRole("link", { name: "Cancel" }).click();

    await expect(teacher.page.getByRole("link", { name: "Edit Rule" }))
      .toBeVisible();
    await expect(teacher.page.locator("#rule-editor-frame").getByText("60%"))
      .toBeVisible();
  });
});
