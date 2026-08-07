import { enableFeature } from "../_support/backend";
import { expect, test } from "../_support/fixtures";
import { FactoryBot, FactoryBotObject } from "../_support/factorybot";
import { AssessmentDashboardPage } from "../page-objects/assessment_dashboard_page";
import { createEligibilityLecture } from "./helpers";

/**
 * Who may sit the exam. The rule proposes, the teacher decides — either one by
 * one or by accepting all open proposals at once. Nothing here is automatic:
 * a proposal only becomes a decision once somebody says so.
 */
test.describe("exam eligibility decisions", () => {
  test.beforeEach(async ({ request }) => {
    await enableFeature(request, "assessment_grading");
    await enableFeature(request, "student_performance");
  });

  async function lectureWithRule(
    factory: FactoryBot,
    teacherId: number,
    percentages: number[],
  ): Promise<FactoryBotObject> {
    const lecture = await createEligibilityLecture(factory, teacherId);
    await factory.create("student_performance_rule", ["active"], {
      lecture_id: lecture.id,
      threshold_mode: "percentage",
      min_percentage: 50,
    });
    for (const percentage of percentages) {
      await factory.create("student_performance_record", [], {
        lecture_id: lecture.id,
        points_total_materialized: percentage,
        points_max_materialized: 100,
        percentage_materialized: percentage,
      });
    }
    return lecture;
  }

  async function openEligibility(page: AssessmentDashboardPage) {
    await page.gotoOverview();
    await page.overviewTab("Exam Eligibility").click();
  }

  test("counts everyone as undecided before anything is accepted", async ({
    factory,
    teacher,
  }) => {
    const lecture = await lectureWithRule(factory, teacher.user.id, [80, 30]);

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await openEligibility(page);

    await expect(teacher.page.getByRole("link", { name: "Undecided" }))
      .toBeVisible();
    await expect(teacher.page.getByRole("button", {
      name: "Accept Open Proposals",
    })).toBeVisible();
    expect(await lecture.__call("student_performance_certifications"))
      .toHaveLength(0);
  });

  test("turns the open proposals into decisions in one go", async ({
    factory,
    teacher,
  }) => {
    const lecture = await lectureWithRule(factory, teacher.user.id, [80, 30]);

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await openEligibility(page);
    await teacher.page.getByRole("button", { name: "Accept Open Proposals" })
      .click();

    await expect(teacher.page.getByText("decisions accepted.")).toBeVisible();
    expect(await lecture.__call("student_performance_certifications"))
      .toHaveLength(2);
  });

  test("says so when there is no rule to propose anything", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createEligibilityLecture(factory, teacher.user.id);
    await factory.create("student_performance_record", [], {
      lecture_id: lecture.id,
      points_total_materialized: 80,
      points_max_materialized: 100,
      percentage_materialized: 80,
    });

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await openEligibility(page);

    await expect(teacher.page.getByText("No active eligibility rule configured"))
      .toBeVisible();
    await expect(teacher.page.getByRole("button", {
      name: "Accept Open Proposals",
    })).toHaveCount(0);
  });

  test("still lets a teacher decide by hand without any rule", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createEligibilityLecture(factory, teacher.user.id);
    await factory.create("student_performance_record", [], {
      lecture_id: lecture.id,
      points_total_materialized: 80,
      points_max_materialized: 100,
      percentage_materialized: 80,
    });

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await openEligibility(page);

    await expect(teacher.page.getByText(
      "You can record decisions manually per student at any time",
    )).toBeVisible();
  });

  test("reports an empty lecture instead of an empty table", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createEligibilityLecture(factory, teacher.user.id);

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await openEligibility(page);

    await expect(teacher.page.getByText("No student records found."))
      .toBeVisible();
  });
});
