import { expect, test } from "../_support/fixtures";
import { AssessmentDashboardPage } from "../page-objects/assessment_dashboard_page";
import { createAssessedAssignment } from "./helpers";

/**
 * The dashboard is streamed into the lecture's assessment tab and has no page
 * of its own, so its address only ever reaches a teacher through the link on
 * the overview — by opening it in a new tab, or by copying it.
 */
test.describe("reaching a dashboard by its address", () => {
  test("lands on the lecture's assessment tab with the dashboard open", async ({
    factory,
    teacher,
  }) => {
    const { lecture, assignment, assessmentId }
      = await createAssessedAssignment(factory, teacher.user.id);

    await teacher.page.goto(
      `/assessment/assessments/${assessmentId}`
      + `?assessable_type=Assignment&assessable_id=${assignment.id}&tab=tasks`,
    );

    await expect(teacher.page).toHaveURL(new RegExp(`/lectures/${lecture.id}/edit`));

    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await expect(dashboard.dashboard).toBeVisible();
    await expect(dashboard.dashboard.getByRole("heading", { name: "Problem Set 1" }))
      .toBeVisible();
    await expect(dashboard.tab("Tasks")).toHaveAttribute("aria-selected", "true");
  });

  test("keeps the overview when no assessment is named", async ({
    factory,
    teacher,
  }) => {
    const { lecture } = await createAssessedAssignment(factory, teacher.user.id);

    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.gotoOverview();

    await expect(teacher.page.getByRole("link", { name: "Problem Set 1" }))
      .toBeVisible();
    await expect(dashboard.dashboard).toHaveCount(0);
  });
});
