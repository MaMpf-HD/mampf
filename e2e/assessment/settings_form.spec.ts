import { expect, test } from "../_support/fixtures";
import { AssessmentDashboardPage } from "../page-objects/assessment_dashboard_page";
import { createAssessedAssignment } from "./helpers";

/**
 * Saving is offered only while a field differs from the value it was loaded
 * with. That comparison happens entirely in the browser, so nothing on the
 * server can tell whether the button appears when it should — or, worse,
 * whether cancelling really puts every field back.
 */
test.describe("assessment settings form", () => {
  test("offers saving only while a field differs from what was loaded", async ({
    factory,
    teacher,
  }) => {
    const { lecture } = await createAssessedAssignment(factory, teacher.user.id);

    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.open("Problem Set 1");

    const title = dashboard.pane.getByLabel("Title");
    await expect(title).toHaveValue("Problem Set 1");
    await expect(dashboard.saveButton).toBeHidden();
    await expect(dashboard.unsavedChangesWarning).toBeHidden();

    await title.fill("Problem Set 2");
    await expect(dashboard.saveButton).toBeVisible();
    await expect(dashboard.unsavedChangesWarning).toBeVisible();

    // an edit that has been undone is not an unsaved change
    await title.fill("Problem Set 1");
    await expect(dashboard.saveButton).toBeHidden();
    await expect(dashboard.unsavedChangesWarning).toBeHidden();
  });

  test("puts text, select and checkbox back on cancel", async ({
    factory,
    teacher,
  }) => {
    const { lecture } = await createAssessedAssignment(factory, teacher.user.id);

    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.open("Problem Set 1");

    const title = dashboard.pane.getByLabel("Title");
    const fileType = dashboard.pane.getByLabel("Submission format");
    const requiresSubmission = dashboard.pane.getByRole("checkbox", {
      name: "Requires digital submission",
    });

    const originalFileType = await fileType.inputValue();
    const originallyChecked = await requiresSubmission.isChecked();

    await title.fill("Changed");
    await fileType.selectOption(".zip");
    await requiresSubmission.setChecked(!originallyChecked);
    await expect(dashboard.saveButton).toBeVisible();

    await dashboard.cancelButton.click();

    await expect(title).toHaveValue("Problem Set 1");
    await expect(fileType).toHaveValue(originalFileType);
    expect(await requiresSubmission.isChecked()).toBe(originallyChecked);
    await expect(dashboard.saveButton).toBeHidden();
  });

  test("takes the saved values as the new baseline", async ({
    factory,
    teacher,
  }) => {
    const { lecture, assignment }
      = await createAssessedAssignment(factory, teacher.user.id);

    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.open("Problem Set 1");

    await dashboard.pane.getByLabel("Title").fill("Problem Set 2");
    await dashboard.saveButton.click();

    await expect(teacher.page.getByText("Assessment updated successfully."))
      .toBeVisible();
    await expect(dashboard.saveButton).toBeHidden();
    expect(await assignment.__call("title")).toBe("Problem Set 2");

    // typing what it used to say is a change again, not a return to the original
    await dashboard.pane.getByLabel("Title").fill("Problem Set 1");
    await expect(dashboard.saveButton).toBeVisible();
  });

  test("guards the lecture submission settings the same way", async ({
    factory,
    teacher,
  }) => {
    const { lecture } = await createAssessedAssignment(factory, teacher.user.id);

    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.gotoOverview();

    const form = dashboard.submissionSettingsForm;
    const teamSize = form.getByLabel("maximal team size for submissions");
    const saveButton = form.getByRole("button", { name: "Save", exact: true });

    await expect(saveButton).toBeHidden();

    await teamSize.fill("3");
    await expect(saveButton).toBeVisible();

    await saveButton.click();

    await expect(teacher.page.getByText("Submission settings successfully updated."))
      .toBeVisible();
    await expect(saveButton).toBeHidden();
    expect(await lecture.__call("submission_max_team_size")).toBe(3);
  });
});
