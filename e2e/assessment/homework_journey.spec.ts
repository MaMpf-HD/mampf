import { expect, test } from "../_support/fixtures";
import { attachToUploadArea } from "../_support/uploads";
import { dateLabel } from "../page-objects/datepicker";
import { AssessmentDashboardPage } from "../page-objects/assessment_dashboard_page";
import { SubmissionsPage } from "../page-objects/submissions_page";

/**
 * One sheet, start to finish, through three pairs of hands: the teacher puts
 * it up, a student hands in, the deadline passes, the tutor marks it and
 * uploads the correction, the student reads the points and takes the
 * correction home. The suites around this one each prove a stretch of that
 * road with the state before it laid down by the factory; this is the one
 * test in which what one person saves is what the next person sees.
 */
test.describe("a homework sheet from the teacher to the student and back", () => {
  test("is created, handed in, marked, corrected and read", async ({
    factory,
    timeCop,
    teacher,
    tutor,
    student,
  }) => {
    const lecture = await factory.create("lecture", ["released_for_all"], {
      teacher_id: teacher.user.id,
      locale: "en",
    });
    const tutorial = await factory.create("tutorial", ["with_tutor_by_id"], {
      lecture_id: lecture.id,
      tutor_id: tutor.user.id,
      title: "Monday group",
    });
    await factory.create("lecture_bookmark", [], {
      lecture_id: lecture.id, user_id: student.user.id,
    });
    await factory.create("lecture_membership", [], {
      lecture_id: lecture.id, user_id: student.user.id,
    });
    await factory.create("tutorial_membership", [], {
      tutorial_id: tutorial.id, user_id: student.user.id,
    });
    const medium = await factory.create("lecture_medium", ["with_lecture_by_id"], {
      lecture_id: lecture.id,
      sort: "Exercise",
    });
    const studentName = student.user.name_in_tutorials;

    // the teacher publishes the sheet and gets an assignment with it, worth
    // ten points on one problem
    await teacher.page.goto(`/media/${medium.id}/edit`);
    await teacher.page.getByRole("button", { name: "publish" }).click();
    const modal = teacher.page.locator("#publishMediumModal");
    await modal.getByRole("checkbox", { name: "Create an assignment" }).check();
    await modal.getByLabel("Title").fill("Sheet 1");
    await modal.locator("#assignment-date-picker [data-td-toggle]").click();
    await teacher.page.locator(".tempus-dominus-widget.show")
      .getByRole("gridcell", { name: dateLabel() }).click();
    await expect(modal.getByLabel("Due date")).not.toHaveValue("");
    await modal.getByRole("checkbox", { name: "I hereby confirm that" }).check();
    await modal.getByRole("button", { name: "Save" }).click();

    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.open("Sheet 1");
    await dashboard.tab("Tasks").click();
    await dashboard.pane.getByLabel("Max Points").fill("10");
    await dashboard.pane.getByRole("button", { name: "Add Task" }).click();
    await expect(dashboard.tasks).toHaveText([/10 pts/]);

    // the student hands a file in while the sheet is open
    const submissions = new SubmissionsPage(student.page, lecture.id);
    await submissions.goto();
    await expect(student.page.getByRole("heading", { name: "Sheet 1" })).toBeVisible();
    await submissions.createSubmission();
    await expect(student.page.getByRole("link", { name: "manuscript.pdf" }))
      .toBeVisible();

    // the deadline passes - the due date was two days out, the grace period
    // is minutes
    await timeCop.travelToDate(new Date(Date.now() + 4 * 86400000));

    // the tutor finds the hand-in in the group's table, marks it and uploads
    // the correction
    await tutor.page.goto(`/lectures/${lecture.id}/tutorials`);
    const row = tutor.page.getByRole("table").getByRole("row", { name: studentName });
    await expect(row.getByText("Pending Grading")).toBeVisible();
    await row.getByRole("spinbutton", { name: `Task 1 for ${studentName}` }).fill("7");
    await row.getByRole("button", { name: "Save this row's points" }).click();
    await expect(row.getByText("Reviewed")).toBeVisible();

    await row.getByRole("link", { name: "Upload correction" }).click();
    await attachToUploadArea(tutor.page, "form.correction-upload",
      "e2e/files/manuscript-mampfsty.pdf");
    const corrected = tutor.page.waitForResponse(
      response => response.url().includes("/add_correction") && response.ok(),
    );
    await row.getByRole("button", { name: "Save", exact: true }).click();
    await corrected;
    await expect(row.getByRole("link", { name: "Download correction" })).toBeVisible();

    // the student finds the points and the correction, and can take the
    // file home
    await submissions.goto();
    const list = student.page.getByRole("region", { name: "Earlier sheets" });
    await expect(list.getByText("New since you last looked:")).toBeVisible();
    await list.getByRole("link", { name: "Sheet 1" }).click();
    await expect(list.getByText("Points per problem")).toBeVisible();
    // the sheet's total and its one problem read the same
    await expect(list.getByText("7 of 10 points")).toHaveCount(2);
    const correction = list.getByRole("link", { name: "Correction: manuscript-mampfsty.pdf" });
    await expect(correction).toBeVisible();

    const href = await correction.getAttribute("href");
    const file = await student.page.request.get(`${href}?download=true`);
    expect(file.ok()).toBe(true);
    expect(file.headers()["content-type"]).toContain("application/pdf");
    expect(file.headers()["content-disposition"]).toContain("manuscript-mampfsty.pdf");
    expect((await file.body()).length).toBeGreaterThan(0);
  });
});
