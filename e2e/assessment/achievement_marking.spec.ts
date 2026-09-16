import { expect, test } from "../_support/fixtures";
import { AssessmentDashboardPage } from "../page-objects/assessment_dashboard_page";
import { createLecture } from "./helpers";

/**
 * A criterion is recorded the way a sheet is marked: the tutor picks it on
 * their page next to the sheets and enters a value per student, the lecturer
 * sees every group in the criterion's dashboard and can excuse somebody with
 * a certificate. What either records, the performance overview shows.
 */
test.describe("marking a criterion", () => {
  test("is recorded by the tutor, excused by the lecturer, and read off the overview", async ({
    factory,
    teacher,
    tutor,
  }) => {
    const lecture = await createLecture(factory, teacher.user.id);
    const tutorial = await factory.create("tutorial", ["with_tutor_by_id"], {
      lecture_id: lecture.id, tutor_id: tutor.user.id, title: "Monday group",
    });
    await factory.create("achievement", ["boolean"], {
      lecture_id: lecture.id, title: "Blackboard talk",
    });
    await factory.create("achievement", ["numeric"], {
      lecture_id: lecture.id, title: "Lab attendance", threshold: 12,
    });
    for (const name of ["Ada Lovelace", "Grace Hopper"]) {
      const student = await factory.create("confirmed_user", [], { name_in_tutorials: name });
      await factory.create("lecture_membership", [], {
        lecture_id: lecture.id, user_id: student.id,
      });
      await factory.create("tutorial_membership", [], {
        tutorial_id: tutorial.id, user_id: student.id,
      });
    }

    // the tutor's page opens on the first criterion, there being no sheet
    // yet, and the tutor records a yes/no one and then a number
    await tutor.page.goto(`/lectures/${lecture.id}/tutorials?tutorial=${tutorial.id}`);
    await expect(tutor.page.getByLabel("Sheet, test or criterion"))
      .toHaveValue("Blackboard talk");
    await expect(tutor.page.getByText("2 not yet graded")).toBeVisible();
    const ada = tutor.page.getByRole("table").getByRole("row", { name: /Ada Lovelace/ });
    await ada.getByRole("combobox", { name: "Value for Ada Lovelace" }).selectOption("met");
    await ada.getByRole("button", { name: "Save this row's value" }).click();
    await expect(ada.getByRole("img", { name: "Met" })).toBeVisible();
    await expect(tutor.page.getByText("1 met · 1 not yet graded")).toBeVisible();

    await tutor.page.getByLabel("Sheet, test or criterion").selectOption("Lab attendance");
    await expect(tutor.page.getByText("Numeric · threshold 12")).toBeVisible();
    const grace = tutor.page.getByRole("table").getByRole("row", { name: /Grace Hopper/ });
    await grace.getByRole("spinbutton", { name: "Value for Grace Hopper" }).fill("9");
    await grace.getByRole("button", { name: "Save this row's value" }).click();
    await expect(grace.getByRole("img", { name: "Not met" })).toBeVisible();

    // the lecturer sees the group's work in the criterion's dashboard, and
    // excuses Grace with a certificate
    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.gotoOverview();
    await dashboard.overviewTab("Achievements").click();
    await teacher.page.getByRole("link", { name: "Lab attendance" }).click();
    const graceRow = teacher.page.getByRole("table").getByRole("row", { name: /Grace Hopper/ });
    await expect(graceRow).toContainText("Monday group");
    await expect(graceRow.getByRole("img", { name: "Not met" })).toBeVisible();
    await graceRow.getByRole("button", { name: "Excuse with a certificate" }).click();
    const dialog = teacher.page.getByRole("dialog", { name: "Excuse from the criterion" });
    await dialog.getByLabel("Reason (optional, teaching staff only)").fill("sick note");
    await dialog.getByRole("button", { name: "Excuse" }).click();
    await expect(graceRow.getByRole("img", { name: "Excused" })).toBeVisible();
    await expect(graceRow.getByRole("spinbutton")).toHaveCount(0);

    // the overview reads the criterion as met for both: Ada's talk, Grace's
    // certificate
    await dashboard.gotoOverview();
    await dashboard.overviewTab("Performance").click();
    const adaRecord = teacher.page.getByRole("row", { name: /Ada Lovelace/ });
    const graceRecord = teacher.page.getByRole("row", { name: /Grace Hopper/ });
    await expect(adaRecord.getByRole("img", { name: "Met" })).toHaveCount(1);
    await expect(graceRecord.getByRole("img", { name: "Met" })).toHaveCount(1);
    await expect(graceRecord.getByRole("img", { name: "Not met" })).toHaveCount(0);
  });
});
