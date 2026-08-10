import { enableFeature } from "../_support/backend";
import { expect, test } from "../_support/fixtures";
import { dateLabel, selectDate } from "../page-objects/datepicker";
import { AssessmentDashboardPage } from "../page-objects/assessment_dashboard_page";
import { createAssessedAssignment, markSomebody } from "./helpers";

/**
 * The plainest thing a teacher does here: put a homework sheet on the page,
 * change it, take it off again. The request specs prove the endpoints answer;
 * only a browser proves there is a way to reach them.
 */
test.describe("homework sheets", () => {
  test.beforeEach(async ({ request }) => {
    await enableFeature(request, "assessment_grading");
  });

  test("creates one and lands on its dashboard", async ({ factory, teacher }) => {
    const lecture = await factory.create("lecture", ["released_for_all"], {
      teacher_id: teacher.user.id,
      locale: "en",
    });

    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.gotoOverview();
    await teacher.page.getByRole("link", { name: "Add assignment" }).click();

    await dashboard.container.getByLabel("Title").fill("Problem Set 1");
    await dashboard.container.getByLabel("Due date").click();
    await selectDate(teacher.page);
    await dashboard.container.getByRole("button", { name: "Save" }).click();

    await expect(dashboard.dashboard.getByRole("heading", { name: "Problem Set 1" }))
      .toBeVisible();
    await expect(dashboard.tab("Tasks")).toHaveAttribute("aria-selected", "true");

    // and it is on the overview the next time the teacher comes back
    await dashboard.gotoOverview();
    await expect(teacher.page.getByRole("link", { name: "Problem Set 1" }))
      .toBeVisible();
  });

  test("keeps the form and the entered title when the title is taken", async ({
    factory,
    teacher,
  }) => {
    const { lecture } = await createAssessedAssignment(factory, teacher.user.id);

    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.gotoOverview();
    await teacher.page.getByRole("link", { name: "Add assignment" }).click();

    await dashboard.container.getByLabel("Title").fill("Problem Set 1");
    await dashboard.container.getByLabel("Due date").click();
    await selectDate(teacher.page);
    await dashboard.container.getByRole("button", { name: "Save" }).click();

    await expect(dashboard.container.getByLabel("Title")).toHaveValue("Problem Set 1");
    await expect(dashboard.dashboard).toHaveCount(0);
  });

  test("creates one while publishing an exercise medium", async ({
    factory,
    teacher,
  }) => {
    const lecture = await factory.create("lecture", ["released_for_all"], {
      teacher_id: teacher.user.id,
      locale: "en",
    });
    const medium = await factory.create("lecture_medium", ["with_lecture_by_id"], {
      lecture_id: lecture.id,
      sort: "Exercise",
    });

    await teacher.page.goto(`/media/${medium.id}/edit`);
    await teacher.page.getByRole("button", { name: "publish" }).click();

    const modal = teacher.page.locator("#publishMediumModal");
    await modal.getByRole("checkbox", { name: "Create an assignment" }).check();
    await modal.getByLabel("Title").fill("Sheet from the medium");
    // the calendar is appended to the body, not to the field, and the modal
    // carries a second one for the release date — so click inside whichever
    // is on screen and make sure the value landed where it was meant to
    const deadline = modal.getByLabel("Due date");
    await modal.locator("#assignment-date-picker [data-td-toggle]").click();
    await teacher.page.locator(".tempus-dominus-widget.show")
      .getByRole("gridcell", { name: dateLabel() }).click();
    await expect(deadline).not.toHaveValue("");
    await modal.getByRole("checkbox", { name: "Requires digital submission" })
      .uncheck();
    await modal.getByRole("checkbox", { name: "I hereby confirm that" }).check();
    await modal.getByRole("button", { name: "Save" }).click();

    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.open("Sheet from the medium");

    await expect(dashboard.dashboard
      .getByRole("heading", { name: "Sheet from the medium" })).toBeVisible();
    await expect(dashboard.pane.getByRole("checkbox", {
      name: "Requires digital submission",
    })).not.toBeChecked();
  });

  test("renames one from its settings", async ({ factory, teacher }) => {
    const { lecture, assignment }
      = await createAssessedAssignment(factory, teacher.user.id);

    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.open("Problem Set 1");

    await dashboard.pane.getByLabel("Title").fill("Problem Set 2");
    await dashboard.saveButton.click();

    await expect(teacher.page.getByText("Assessment updated successfully."))
      .toBeVisible();
    expect(await assignment.__call("title")).toBe("Problem Set 2");

    await dashboard.gotoOverview();
    await expect(teacher.page.getByRole("link", { name: "Problem Set 2" }))
      .toBeVisible();
  });

  test("deletes one and leaves the empty state behind", async ({
    factory,
    teacher,
  }) => {
    const { lecture } = await createAssessedAssignment(factory, teacher.user.id);

    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.open("Problem Set 1");

    teacher.page.on("dialog", dialog => dialog.accept());
    await dashboard.pane.getByRole("button", { name: "Delete" }).click();

    await expect(teacher.page.getByText("No assignments created yet.")).toBeVisible();

    await dashboard.gotoOverview();
    await expect(teacher.page.getByRole("link", { name: "Problem Set 1" }))
      .toHaveCount(0);
  });

  test("refuses to delete one that has already been marked", async ({
    factory,
    teacher,
  }) => {
    const { lecture, assessmentId }
      = await createAssessedAssignment(factory, teacher.user.id, "Problem Set 1",
        ["expired"]);
    await markSomebody(factory, assessmentId);

    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.open("Problem Set 1");

    const deleteButton = dashboard.pane.getByRole("button", { name: "Delete" });
    await expect(deleteButton).toBeDisabled();
    await expect(dashboard.pane.getByTitle("Cannot delete: Grading data exists"))
      .toBeVisible();
  });
});
