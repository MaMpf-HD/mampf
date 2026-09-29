import { expect, test } from "../_support/fixtures";
import { AssessmentDashboardPage } from "../page-objects/assessment_dashboard_page";
import { createLecture } from "./helpers";

/**
 * An achievement is either done-or-not or measured against a threshold, and the
 * form rearranges itself accordingly. That rearranging, and the guard against
 * losing unsaved edits, happen entirely in the browser.
 */
test.describe("the achievement form", () => {
  async function openNewForm(page: AssessmentDashboardPage) {
    await page.gotoOverview();
    await page.overviewTab("Achievements").click();
    await page.page.getByRole("link", { name: "New Achievement" }).click();
  }

  async function openSettings(page: AssessmentDashboardPage, title: string) {
    await page.gotoOverview();
    await page.overviewTab("Achievements").click();
    await page.page.getByRole("link", { name: title }).click();
  }

  test("shows the threshold only where it means something", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await openNewForm(page);

    const type = page.container.getByLabel("Type");
    const threshold = page.container.getByLabel("Threshold");

    // "Yes/No" is the default, and a yes-or-no achievement has no threshold
    await expect(threshold).toBeHidden();

    await type.selectOption("numeric");
    await expect(threshold).toBeVisible();

    await type.selectOption("percentage");
    await expect(threshold).toBeVisible();

    await type.selectOption("boolean");
    await expect(threshold).toBeHidden();
  });

  test("drops a threshold that no longer applies", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await openNewForm(page);

    await page.container.getByLabel("Type").selectOption("numeric");
    await page.container.getByLabel("Threshold").fill("12");

    await page.container.getByLabel("Type").selectOption("boolean");
    await page.container.getByLabel("Type").selectOption("numeric");

    // switching away and back must not smuggle the old number back in
    await expect(page.container.getByLabel("Threshold")).toHaveValue("");
  });

  test("offers saving only once something differs", async ({
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
    await openSettings(page, "Lab attendance");

    const save = page.container.getByRole("button", { name: "Save" });
    const title = page.container.getByLabel("Title");
    await expect(save).toBeHidden();

    await title.fill("Lab attendance, revised");
    await expect(save).toBeVisible();

    await title.fill("Lab attendance");
    await expect(save).toBeHidden();

    // the threshold counts as much as the title
    await page.container.getByLabel("Threshold").fill("15");
    await expect(save).toBeVisible();
  });

  test("puts every field back on cancel, including the threshold", async ({
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
    await openSettings(page, "Lab attendance");

    await page.container.getByLabel("Title").fill("Something else");
    await page.container.getByLabel("Threshold").fill("15");
    await page.container.getByLabel("Description").fill("A note");
    await expect(page.container.getByRole("button", { name: "Save" }))
      .toBeVisible();

    await page.container.getByRole("button", { name: "Cancel" }).click();

    await expect(page.container.getByLabel("Title")).toHaveValue("Lab attendance");
    await expect(page.container.getByLabel("Threshold")).toHaveValue("12.0");
    await expect(page.container.getByLabel("Description")).toHaveValue("");
    await expect(page.container.getByRole("button", { name: "Save" }))
      .toBeHidden();
  });

  test("keeps offering to save after the server refused", async ({
    factory,
    teacher,
  }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    await factory.create("achievement", ["boolean"], {
      lecture_id: lecture.id,
      title: "Blackboard talk",
    });
    await factory.create("achievement", ["numeric"], {
      lecture_id: lecture.id,
      title: "Lab attendance",
      threshold: 12,
    });

    const page = new AssessmentDashboardPage(teacher.page, lecture.id);
    await openSettings(page, "Lab attendance");

    // a title the lecture already uses
    await page.container.getByLabel("Title").fill("Blackboard talk");
    await page.container.getByRole("button", { name: "Save" }).click();

    await expect(page.container.getByRole("button", { name: "Save" }))
      .toBeVisible();
    await expect(page.container.getByLabel("Title"))
      .toHaveValue("Blackboard talk");
  });
});
