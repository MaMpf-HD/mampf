import { User } from "../_support/auth";
import { expect, test } from "../_support/fixtures";
import { FactoryBot, FactoryBotObject } from "../_support/factorybot";
import { AssessmentDashboardPage } from "../page-objects/assessment_dashboard_page";
import { SubmissionsPage } from "../page-objects/submissions_page";

async function seat(
  factory: FactoryBot,
  lecture: FactoryBotObject,
  seats: Array<[User, FactoryBotObject]>,
) {
  for (const [user, tutorial] of seats) {
    await factory.create("lecture_bookmark", [], { lecture_id: lecture.id, user_id: user.id });
    await factory.create("lecture_membership", [], {
      lecture_id: lecture.id, user_id: user.id,
    });
    await factory.create("tutorial_membership", [], {
      tutorial_id: tutorial.id, user_id: user.id,
    });
  }
}

test.describe("a team across tutorials", () => {
  test("is filed by load, handed over by a tutor, and read by the other", async ({
    factory,
    timeCop,
    teacher,
    tutor,
    tutor2,
    student,
    student2,
  }) => {
    // Two students, two tutors, a hand-in, a join, a hand-over and marking.
    test.slow();
    const lecture = await factory.create("lecture", ["released_for_all"], {
      teacher_id: teacher.user.id,
    });
    const monday = await factory.create("tutorial", ["with_tutor_by_id"], {
      lecture_id: lecture.id, tutor_id: tutor.user.id, title: "Monday group",
    });
    const tuesday = await factory.create("tutorial", ["with_tutor_by_id"], {
      lecture_id: lecture.id, tutor_id: tutor2.user.id, title: "Tuesday group",
    });
    await seat(factory, lecture, [[student.user, monday], [student2.user, tuesday]]);
    const assignment = await factory.create("assignment", [], {
      lecture_id: lecture.id,
      title: "Homework 1",
      deadline: new Date(Date.now() + 7 * 86400000).toISOString(),
    });
    const assessment = await assignment.__call("assessment");
    await factory.create("assessment_task", [], {
      assessment_id: assessment.id, max_points: 10,
    });

    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.gotoOverview();
    const form = dashboard.submissionSettingsForm;
    await form.getByLabel("allow submission teams across tutorials").check();
    await form.getByRole("button", { name: "Save", exact: true }).click();
    await expect(teacher.page.getByText("Submission settings successfully updated."))
      .toBeVisible();
    await expect(form.getByLabel("allow submission teams across tutorials")).toBeChecked();
    // Monday's tutorial already has a hand-in, so the team goes to Tuesday's
    // although the uploader is in Monday's.
    const busy = await factory.create("confirmed_user", [], { name_in_tutorials: "Ada Lovelace" });
    await factory.create("tutorial_membership", [], {
      tutorial_id: monday.id, user_id: busy.id,
    });
    const other = await factory.create("submission", ["with_manuscript"], {
      assignment_id: assignment.id, tutorial_id: monday.id,
    });
    await factory.create("user_submission_join", [], {
      submission_id: other.id, user_id: busy.id,
    });

    const page = new SubmissionsPage(student.page, lecture.id);
    await page.goto();
    await page.createSubmission();
    const ownCard = student.page.getByRole("region", { name: "Homework 1" });
    await expect(ownCard.getByText(/Monday group/)).toBeVisible();
    const code = await student.page.locator("code").innerText();

    await student2.page.goto(`/lectures/${lecture.id}/submissions`);
    const card = student2.page.getByRole("region", { name: "Homework 1" });
    await card.getByRole("link", { name: "Join with a code" }).click();
    await student2.page.getByRole("textbox", { name: "Code" }).fill(code);
    await student2.page.getByRole("button", { name: "Join" }).click();
    await expect(card.getByText(student.user.name_in_tutorials)).toBeVisible();
    await expect(card.getByText(/Tuesday group/)).toBeVisible();

    const deadline = new Date(await assignment.__call("deadline") as string);
    await timeCop.travelToDate(new Date(deadline.getTime() + 2 * 86400000));

    const tablePath = (tutorialId: number) =>
      `/lectures/${lecture.id}/tutorials?assignment=${assignment.id}&tutorial=${tutorialId}`;
    await tutor2.page.goto(tablePath(tuesday.id));
    const tuesdayTable = tutor2.page.getByRole("table");
    const teamAtTuesday = tuesdayTable.getByRole("row", { name: student.user.name_in_tutorials });
    await expect(teamAtTuesday.getByRole("spinbutton")).toBeEnabled();
    await teamAtTuesday.getByRole("button", { name: "Hand this team over to another tutorial" })
      .click();
    await teamAtTuesday.getByRole("button", { name: /Monday group/ }).click();

    await expect(tutor2.page.getByText("Handed over to Monday group.")).toBeVisible();
    const readOnly = tuesdayTable.getByRole("row", { name: student.user.name_in_tutorials });
    await expect(readOnly.getByText(/Marked in Monday group/)).toBeVisible();
    await expect(readOnly.getByRole("spinbutton")).toBeDisabled();
    await expect(readOnly.getByRole("button", { name: "Hand this team over to another tutorial" }))
      .toHaveCount(0);

    await tutor.page.goto(tablePath(monday.id));
    const teamAtMonday = tutor.page.getByRole("table")
      .getByRole("row", { name: student.user.name_in_tutorials });
    await teamAtMonday.getByRole("spinbutton").fill("7");
    await teamAtMonday.getByRole("button", { name: "Save this row's points" }).click();
    await expect(teamAtMonday.getByText("Reviewed")).toBeVisible();
    await expect(teamAtMonday.getByRole("button", {
      name: "Hand this team over to another tutorial",
    })).toHaveCount(0);

    await tutor2.page.reload();
    const marked = tutor2.page.getByRole("table")
      .getByRole("row", { name: student.user.name_in_tutorials });
    await expect(marked.getByText("Reviewed")).toBeVisible();
    await expect(marked.getByRole("spinbutton")).toHaveValue("7.0");
    await expect(marked.getByRole("spinbutton")).toBeDisabled();
    const fileLink = marked.getByRole("link", { name: "View hand-in" });
    const file = await tutor2.page.request.get(await fileLink.getAttribute("href") as string);
    expect(file.headers()["content-type"]).toContain("application/pdf");
  });

  test("is refused unless the lecturer allows it", async ({
    factory,
    teacher,
    student,
    student2,
  }) => {
    const lecture = await factory.create("lecture", ["released_for_all"], {
      teacher_id: teacher.user.id,
    });
    const monday = await factory.create("tutorial", [], {
      lecture_id: lecture.id, title: "Monday group",
    });
    const tuesday = await factory.create("tutorial", [], {
      lecture_id: lecture.id, title: "Tuesday group",
    });
    await seat(factory, lecture, [[student.user, monday], [student2.user, tuesday]]);
    await factory.create("assignment", [], {
      lecture_id: lecture.id,
      title: "Homework 1",
      deadline: new Date(Date.now() + 7 * 86400000).toISOString(),
    });

    const page = new SubmissionsPage(student.page, lecture.id);
    await page.goto();
    await page.createSubmission();
    const code = await student.page.locator("code").innerText();

    await student2.page.goto(`/lectures/${lecture.id}/submissions`);
    const card = student2.page.getByRole("region", { name: "Homework 1" });
    await card.getByRole("link", { name: "Join with a code" }).click();
    await student2.page.getByRole("textbox", { name: "Code" }).fill(code);
    await student2.page.getByRole("button", { name: "Join" }).click();

    await expect(student2.page.getByText("this submission team belongs to another tutorial"))
      .toBeVisible();
    await expect(card.getByText(student.user.name_in_tutorials)).toHaveCount(0);
  });
});
