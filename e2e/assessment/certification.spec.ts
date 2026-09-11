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
  async function lectureWithRule(
    factory: FactoryBot,
    teacherId: number,
    percentages: number[],
    { complete = false }: { complete?: boolean } = {},
  ): Promise<FactoryBotObject> {
    const lecture = await createEligibilityLecture(
      factory, teacherId, complete ? { assignments_complete: true } : {},
    );
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

  // Nothing is proposed while sheets can still be added: another one moves both
  // what is reachable and what the threshold asks. So a lecture that is to have
  // proposals has to say its sheets are all in.
  test("turns the open proposals into decisions in one go", async ({
    factory,
    teacher,
  }) => {
    const lecture = await lectureWithRule(
      factory, teacher.user.id, [80, 30], { complete: true },
    );

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await openEligibility(page);
    await teacher.page.getByRole("button", { name: "Accept Open Proposals" })
      .click();

    await expect(teacher.page.getByText("decisions accepted.")).toBeVisible();
    expect(await lecture.__call("student_performance_certifications"))
      .toHaveLength(2);
  });

  // Deciding is done student by student down a filtered list, and the answer
  // has to come back to that list rather than to the top of an unfiltered one.
  test("stays on the searched list after one decision", async ({
    factory,
    teacher,
  }) => {
    const lecture = await lectureWithRule(factory, teacher.user.id, [],
      { complete: true });
    for (const name of ["Ada Lovelace", "Grace Hopper"]) {
      const user = await factory.create("confirmed_user", [], {
        name_in_tutorials: name,
      });
      await factory.create("student_performance_record", [], {
        lecture_id: lecture.id,
        user_id: user.id,
        points_total_materialized: 80,
        points_max_materialized: 100,
        percentage_materialized: 80,
      });
    }

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await openEligibility(page);

    const search = teacher.page.getByRole("textbox", { name: "Search students" });
    await search.fill("Hopper");
    // both sides, because an empty table would satisfy the second on its own
    await expect(teacher.page.getByText("Grace Hopper")).toBeVisible();
    await expect(teacher.page.getByText("Ada Lovelace")).toHaveCount(0);

    await teacher.page.getByRole("button", { name: "Certify: Eligible" })
      .click();

    // the decision landed: only a decided row offers to edit one
    await expect(teacher.page.getByRole("button", { name: "Edit decision" }))
      .toBeVisible();

    await expect(teacher.page.getByText("Grace Hopper")).toBeVisible();
    await expect(teacher.page.getByText("Ada Lovelace")).toHaveCount(0);
    await expect(search).toHaveValue("Hopper");
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
