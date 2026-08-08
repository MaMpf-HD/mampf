import { enableFeature } from "../_support/backend";
import { expect, test } from "../_support/fixtures";
import { AssessmentDashboardPage } from "../page-objects/assessment_dashboard_page";
import { addTask, createLecture, recordFor, scoreTask } from "./helpers";

/**
 * The factual side of the eligibility area: what every member has actually
 * earned, computed from their marked submissions. Nobody edits these numbers
 * here — the screen lists them, narrows them by tutorial group, and lets a
 * teacher look at one student sheet by sheet.
 */
test.describe("performance records", () => {
  test.beforeEach(async ({ request }) => {
    await enableFeature(request, "assessment_grading");
    await enableFeature(request, "student_performance");
  });

  async function openPerformance(page: AssessmentDashboardPage) {
    await page.gotoOverview();
    await page.overviewTab("Performance").click();
  }

  test("lists what it computed for each member", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    await recordFor(factory, lecture.id, "Ada Lovelace", {
      points_total_materialized: 72,
      points_max_materialized: 90,
      percentage_materialized: 80,
    });
    await recordFor(factory, lecture.id, "Grace Hopper", {
      points_total_materialized: 18,
      points_max_materialized: 90,
      percentage_materialized: 20,
    });

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await openPerformance(page);

    const row = teacher.page.getByRole("row", { name: /Ada Lovelace/ });
    await expect(row).toContainText("72");
    await expect(row).toContainText("80");
    await expect(teacher.page.getByText("Grace Hopper")).toBeVisible();
  });

  test("opens one member sheet by sheet", async ({ factory, teacher }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    await factory.create("assignment", [], {
      lecture_id: lecture.id,
      title: "Problem Set 1",
    });
    await recordFor(factory, lecture.id, "Ada Lovelace", {
      points_total_materialized: 72,
      points_max_materialized: 90,
      percentage_materialized: 80,
    });

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await openPerformance(page);
    await teacher.page.getByRole("row", { name: /Ada Lovelace/ })
      .getByRole("link", { name: "Details" }).click();

    await expect(teacher.page.getByText("Ada Lovelace")).toBeVisible();
    await expect(teacher.page.getByText("Assignment Breakdown")).toBeVisible();
    await expect(teacher.page.getByRole("cell", { name: "Problem Set 1" }))
      .toBeVisible();
  });

  test("recomputes one member and picks up what was marked since", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    const assignment = await factory.create("assignment", ["expired"], {
      lecture_id: lecture.id,
      title: "Problem Set 1",
    });
    const assessment = await assignment.__call("assessment");
    const task = await addTask(factory, assessment.id, "Prove it", 10);

    // joining computes a record of its own, and at that moment it is empty
    const member = await factory.create("confirmed_user", [], {
      name_in_tutorials: "Ada Lovelace",
    });
    await factory.create("lecture_membership", [], {
      lecture_id: lecture.id,
      user_id: member.id,
    });

    const participation = await factory.create("assessment_participation", [], {
      assessment_id: assessment.id,
      user_id: member.id,
      status: "reviewed",
      submitted_at: new Date().toISOString(),
    });
    await scoreTask(factory, task.id, participation.id, 7);

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await openPerformance(page);
    await teacher.page.getByRole("row", { name: /Ada Lovelace/ })
      .getByRole("link", { name: "Details" }).click();
    await teacher.page.getByRole("button", { name: "Recompute" }).click();

    await expect(
      teacher.page.getByText("Recomputation for this student completed."),
    ).toBeVisible();
    await expect(teacher.page.getByText("out of 10 possible")).toBeVisible();
    await expect(teacher.page.getByText("70%")).toBeVisible();
  });

  test("narrows the list to one tutorial group", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    const tutorial = await factory.create("tutorial", [], {
      lecture_id: lecture.id,
      title: "Tuesday group",
    });
    const { user: inGroup } = await recordFor(
      factory, lecture.id, "Ada Lovelace",
    );
    await recordFor(factory, lecture.id, "Grace Hopper");
    await factory.create("tutorial_membership", [], {
      tutorial_id: tutorial.id,
      user_id: inGroup.id,
    });

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await openPerformance(page);
    await expect(teacher.page.getByText("Grace Hopper")).toBeVisible();

    await teacher.page.getByRole("combobox").selectOption("Tuesday group");

    await expect(teacher.page.getByText("Ada Lovelace")).toBeVisible();
    await expect(teacher.page.getByText("Grace Hopper")).toHaveCount(0);
  });

  test("finds the members who are in no group at all", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    const tutorial = await factory.create("tutorial", [], {
      lecture_id: lecture.id,
      title: "Tuesday group",
    });
    const { user: inGroup } = await recordFor(
      factory, lecture.id, "Ada Lovelace",
    );
    await recordFor(factory, lecture.id, "Grace Hopper");
    await factory.create("tutorial_membership", [], {
      tutorial_id: tutorial.id,
      user_id: inGroup.id,
    });

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await openPerformance(page);
    await teacher.page.getByRole("combobox")
      .selectOption("Without tutorial group");

    await expect(teacher.page.getByText("Grace Hopper")).toBeVisible();
    await expect(teacher.page.getByText("Ada Lovelace")).toHaveCount(0);
  });

  test("says so while nothing has been computed", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createLecture(factory, teacher.user.id);

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await openPerformance(page);

    await expect(
      teacher.page.getByText("No performance records have been computed yet."),
    ).toBeVisible();
  });

  test("sends a record of another lecture back to the list", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    const other = await createLecture(factory, teacher.user.id);
    const { record } = await recordFor(factory, other.id, "Ada Lovelace");

    await teacher.page.goto(
      `/lectures/${lecture.id}/performance/records/${record.id}`,
    );

    await expect(teacher.page.getByText("Performance record not found."))
      .toBeVisible();
    await expect(teacher.page.getByText("Assignment Breakdown")).toHaveCount(0);
  });

  test("keeps a student out of the records of their own lecture", async ({
    factory,
    teacher,
    student,
  }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    await factory.create("lecture_membership", [], {
      lecture_id: lecture.id,
      user_id: student.user.id,
    });

    await student.page.goto(`/lectures/${lecture.id}/performance/records`);

    await expect(
      student.page.getByText("You are not authorized to access this page."),
    ).toBeVisible();
    await expect(
      student.page.getByText("Factual performance data computed from"),
    ).toHaveCount(0);
  });
});
