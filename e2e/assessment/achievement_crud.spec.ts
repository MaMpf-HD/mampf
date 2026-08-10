import { disableFeature, enableFeature } from "../_support/backend";
import { expect, test } from "../_support/fixtures";
import { AssessmentDashboardPage } from "../page-objects/assessment_dashboard_page";
import { createLecture } from "./helpers";

/**
 * An achievement is a third kind of assessable next to sheets and talks —
 * something a student has to have done that carries no points. It is defined
 * on its own tab of the lecture's assessment area.
 */
test.describe("achievements", () => {
  test.beforeEach(async ({ request }) => {
    await enableFeature(request, "assessment_grading");
    await enableFeature(request, "student_performance");
  });

  test("creates one and shows it in the list", async ({ factory, teacher }) => {
    const lecture = await createLecture(factory, teacher.user.id);

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await page.gotoOverview();
    await page.overviewTab("Achievements").click();

    await expect(teacher.page.getByText("No achievements defined yet."))
      .toBeVisible();

    await teacher.page.getByRole("link", { name: "New Achievement" }).click();
    await page.container.getByLabel("Title").fill("Blackboard talk");
    await page.container.getByLabel("Type").selectOption("boolean");
    await page.container.getByRole("button", { name: "Save" }).click();

    await expect(page.container.getByRole("heading", { name: "Blackboard talk" }))
      .toBeVisible();

    await page.gotoOverview();
    await page.overviewTab("Achievements").click();
    await expect(teacher.page.getByRole("link", { name: "Blackboard talk" }))
      .toBeVisible();
  });

  test("records a threshold for a numeric one", async ({ factory, teacher }) => {
    const lecture = await createLecture(factory, teacher.user.id);

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await page.gotoOverview();
    await page.overviewTab("Achievements").click();
    await teacher.page.getByRole("link", { name: "New Achievement" }).click();

    await page.container.getByLabel("Title").fill("Lab attendance");
    await page.container.getByLabel("Type").selectOption("numeric");
    await page.container.getByLabel("Threshold").fill("12");
    await page.container.getByRole("button", { name: "Save" }).click();

    await page.gotoOverview();
    await page.overviewTab("Achievements").click();

    const row = teacher.page.locator("tr", { hasText: "Lab attendance" });
    await expect(row).toContainText("Numeric");
    await expect(row).toContainText("12");
  });

  test("renames one", async ({ factory, teacher }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    const achievement = await factory.create("achievement", ["boolean"], {
      lecture_id: lecture.id,
      title: "Blackboard talk",
    });

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await page.gotoOverview();
    await page.overviewTab("Achievements").click();
    await teacher.page.getByRole("link", { name: "Blackboard talk" }).click();

    await page.container.getByLabel("Title").fill("Blackboard talk, revised");
    await page.container.getByRole("button", { name: "Save" }).click();

    await expect(teacher.page.getByText("Achievement updated successfully."))
      .toBeVisible();
    expect(await achievement.__call("title")).toBe("Blackboard talk, revised");
  });

  test("deletes one", async ({ factory, teacher }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    await factory.create("achievement", ["boolean"], {
      lecture_id: lecture.id,
      title: "Blackboard talk",
    });

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await page.gotoOverview();
    await page.overviewTab("Achievements").click();
    await teacher.page.getByRole("link", { name: "Blackboard talk" }).click();

    teacher.page.on("dialog", dialog => dialog.accept());
    await page.container.getByRole("button", { name: "Delete" }).click();

    await expect(teacher.page.getByText("Achievement deleted successfully."))
      .toBeVisible();
    await expect(teacher.page.getByText("No achievements defined yet."))
      .toBeVisible();
  });

  test("hides the tab when student performance is switched off", async ({
    request,
    factory,
    teacher,
  }) => {
    const lecture = await createLecture(factory, teacher.user.id);

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await page.gotoOverview();
    await expect(page.overviewTab("Achievements")).toBeVisible();

    await disableFeature(request, "student_performance");
    await page.gotoOverview();
    await expect(page.overviewTab("Achievements")).toHaveCount(0);
  });

  test("opens one by clicking its row, not just its link", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    await factory.create("achievement", ["numeric"], {
      lecture_id: lecture.id,
      title: "Lab attendance",
      threshold: 12,
    });

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await page.gotoOverview();
    await page.overviewTab("Achievements").click();

    // the type cell, well away from the title link
    await teacher.page.locator("tr", { hasText: "Lab attendance" })
      .getByRole("cell").nth(1).click();

    await expect(page.container.getByRole("heading", { name: "Lab attendance" }))
      .toBeVisible();
  });

  test("keeps one when the confirmation is declined", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    await factory.create("achievement", ["boolean"], {
      lecture_id: lecture.id,
      title: "Blackboard talk",
    });

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await page.gotoOverview();
    await page.overviewTab("Achievements").click();
    await teacher.page.getByRole("link", { name: "Blackboard talk" }).click();

    teacher.page.on("dialog", dialog => dialog.dismiss());
    await page.container.getByRole("button", { name: "Delete" }).click();

    await expect(page.container.getByRole("heading", { name: "Blackboard talk" }))
      .toBeVisible();
  });

  test("refuses to delete one that a rule depends on", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    const achievement = await factory.create("achievement", ["boolean"], {
      lecture_id: lecture.id,
      title: "Blackboard talk",
    });
    const rule = await factory.create("student_performance_rule", [], {
      lecture_id: lecture.id,
    });
    await factory.create("student_performance_rule_achievement", [], {
      rule_id: rule.id,
      achievement_id: achievement.id,
    });

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await page.gotoOverview();
    await page.overviewTab("Achievements").click();
    await teacher.page.getByRole("link", { name: "Blackboard talk" }).click();

    teacher.page.on("dialog", dialog => dialog.accept());
    await page.container.getByRole("button", { name: "Delete" }).click();

    await expect(teacher.page.getByText(
      "Cannot delete: Achievement is referenced by a rule.",
    )).toBeVisible();
    await expect(page.container.getByRole("heading", { name: "Blackboard talk" }))
      .toBeVisible();
  });
});
