import { expect, test } from "../_support/fixtures";
import { AssessmentDashboardPage } from "../page-objects/assessment_dashboard_page";
import { createEligibilityLecture } from "./helpers";

/**
 * A test written in the tutorial, start to finish: the teacher puts it up for
 * a week, the student sees the week and nothing to upload, the tutor enters
 * the points during that week without recording a hand-in first, and the
 * student reads them - marked as a test, among the sheets.
 */
test.describe("a test written in the tutorial", () => {
  test("is set for a week, marked in it, and read", async ({
    factory,
    timeCop,
    teacher,
    tutor,
    student,
  }) => {
    const lecture = await factory.create("lecture", ["released_for_all"], {
      teacher_id: teacher.user.id,
    });
    const tutorial = await factory.create("tutorial", ["with_tutor_by_id"], {
      lecture_id: lecture.id, tutor_id: tutor.user.id, title: "Monday group",
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
    const studentName = student.user.name_in_tutorials;

    // the teacher sets the test up for the last week on offer, with one
    // problem; the weeks are the term's, and the term is the factory's, so
    // the week's Monday is read off the form rather than the calendar - the
    // last one is always there, the second is not when the term ends this week
    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.gotoOverview();
    await teacher.page.getByRole("link", { name: "Add test" }).click();
    await expect(dashboard.container.getByRole("heading", { name: "Add test" })).toBeVisible();
    await expect(dashboard.container.getByLabel("Digital submission via MaMpf")).toHaveCount(0);
    await dashboard.container.getByLabel("Title").fill("Test 1");
    const week = dashboard.container.getByLabel("Test week");
    await week.selectOption({ index: await week.getByRole("option").count() - 1 });
    const monday = new Date(`${await week.inputValue()}T12:00:00`);
    await dashboard.container.getByRole("button", { name: "Save" }).click();
    await expect(dashboard.dashboard.getByRole("heading", { name: "Test 1" })).toBeVisible();
    await dashboard.pane.getByLabel("Max Points").fill("10");
    await dashboard.pane.getByRole("button", { name: "Add Task" }).click();
    await expect(dashboard.tasks).toHaveText([/10 pts/]);

    // the overview lists it in the tests' table, with its week
    await dashboard.gotoOverview();
    await expect(teacher.page.getByRole("columnheader", { name: "Test week" })).toBeVisible();
    await expect(teacher.page.getByRole("link", { name: "Test 1" })).toBeVisible();

    // the student sees the week and the tutorial, and nothing to upload
    await student.page.goto(`/lectures/${lecture.id}/submissions`);
    await expect(student.page.getByRole("heading", { name: "Test 1" })).toBeVisible();
    await expect(student.page.getByText("Test week:")).toBeVisible();
    await expect(student.page.getByText("in your tutorial", { exact: false })).toBeVisible();
    await expect(student.page.getByRole("link", { name: "Hand in" })).toHaveCount(0);

    // the week begins: the Monday group writes it, and the tutor enters the
    // points straight away
    await timeCop.travelToDate(monday);

    await tutor.page.goto(`/lectures/${lecture.id}/tutorials`);
    await expect(tutor.page.getByText("Test week:")).toBeVisible();
    const row = tutor.page.getByRole("table").getByRole("row", { name: studentName });
    await expect(row.getByText("Record the hand-in first")).toHaveCount(0);

    // a no-show is recorded as such - and taken back when it turns out to be
    // a mix-up
    await row.getByRole("link", { name: "Record as absent" }).click();
    await expect(row.getByText("Absent")).toBeVisible();
    await expect(row.getByRole("spinbutton", { name: `Task 1 for ${studentName}` }))
      .toBeDisabled();
    await row.getByRole("link", { name: "Take the absence back" }).click();
    await expect(row.getByText("Absent")).toHaveCount(0);

    await row.getByRole("spinbutton", { name: `Task 1 for ${studentName}` }).fill("8");
    await row.getByRole("button", { name: "Save this row's points" }).click();
    await expect(row.getByText("Reviewed")).toBeVisible();

    // the teacher watches the points come in: the test has its own group in
    // the performance table, and a share of its own
    await dashboard.gotoOverview();
    await dashboard.overviewTab("Performance").click();
    await expect(teacher.page.getByRole("columnheader", { name: "Tests Info" })).toBeVisible();
    // the one test is all that has been marked, so the total and the tests'
    // own figures read the same
    const performance = teacher.page.getByRole("row", { name: studentName });
    await expect(performance.getByRole("cell", { name: "8", exact: true })).toHaveCount(2);
    await expect(performance.getByRole("cell", { name: "80%" })).toHaveCount(2);

    // the week still runs for the later groups, but this student has written
    // it: the card is gone, the test sits in the list as news, marked as a test
    await student.page.goto(`/lectures/${lecture.id}/submissions`);
    await expect(student.page.getByRole("heading", { name: "Test 1" })).toHaveCount(0);
    const list = student.page.getByRole("region", { name: "Earlier sheets and tests" });
    await expect(list.getByText("New since you last looked:")).toBeVisible();
    const entry = list.getByRole("group").filter({ hasText: "Test 1" });
    await expect(entry.getByText("Test", { exact: true })).toBeVisible();
    await expect(entry.getByText("8", { exact: true })).toBeVisible();
  });

  test("lasts several weeks and stays open until the last is over", async ({
    factory,
    timeCop,
    teacher,
    tutor,
    student,
  }) => {
    const lecture = await factory.create("lecture", ["released_for_all"], {
      teacher_id: teacher.user.id,
    });
    const tutorial = await factory.create("tutorial", ["with_tutor_by_id"], {
      lecture_id: lecture.id, tutor_id: tutor.user.id, title: "Thursday group",
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

    // the teacher keeps the week the form offers and gives the test two of
    // them; the week's Monday is read off the form, as above
    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.gotoOverview();
    await teacher.page.getByRole("link", { name: "Add test" }).click();
    await dashboard.container.getByLabel("Title").fill("Test 2");
    const monday = new Date(
      `${await dashboard.container.getByLabel("Test week").inputValue()}T12:00:00`,
    );
    await dashboard.container.getByLabel("Duration").selectOption({ label: "2 weeks" });
    await dashboard.container.getByRole("button", { name: "Save" }).click();
    await expect(dashboard.dashboard.getByRole("heading", { name: "Test 2" })).toBeVisible();

    // the student is told both weeks
    const day = 24 * 60 * 60 * 1000;
    const short = { month: "short", day: "numeric" } as const;
    const from = monday.toLocaleDateString("en-US", short);
    const to = new Date(monday.getTime() + 13 * day)
      .toLocaleDateString("en-US", { ...short, year: "numeric" });
    await student.page.goto(`/lectures/${lecture.id}/submissions`);
    await expect(student.page.getByRole("heading", { name: "Test 2" })).toBeVisible();
    await expect(student.page.getByText(`Test weeks: ${from} – ${to}`)).toBeVisible();

    // in the second week the test is still ahead of the later groups
    await timeCop.travelToDate(new Date(monday.getTime() + 8 * day));
    await student.page.goto(`/lectures/${lecture.id}/submissions`);
    await expect(student.page.getByRole("heading", { name: "Test 2" })).toBeVisible();

    // once both weeks are over, it moves to the list
    await timeCop.travelToDate(new Date(monday.getTime() + 15 * day));
    await student.page.goto(`/lectures/${lecture.id}/submissions`);
    await expect(student.page.getByRole("heading", { name: "Test 2" })).toHaveCount(0);
    const list = student.page.getByRole("region", { name: "Earlier sheets and tests" });
    await expect(list.getByRole("group").filter({ hasText: "Test 2" })).toBeVisible();
  });

  test("can be set up for last week and marked at once", async ({
    factory,
    teacher,
    tutor,
    student,
  }) => {
    // without a term, last week heads the list on any day of the year
    const lecture = await factory.create("lecture", ["term_independent", "released_for_all"], {
      teacher_id: teacher.user.id,
    });
    const tutorial = await factory.create("tutorial", ["with_tutor_by_id"], {
      lecture_id: lecture.id, tutor_id: tutor.user.id, title: "Friday group",
    });
    await factory.create("lecture_membership", [], {
      lecture_id: lecture.id, user_id: student.user.id,
    });
    await factory.create("tutorial_membership", [], {
      tutorial_id: tutorial.id, user_id: student.user.id,
    });
    const studentName = student.user.name_in_tutorials;

    // the teacher picks last week over the week the form offers
    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.gotoOverview();
    await teacher.page.getByRole("link", { name: "Add test" }).click();
    await dashboard.container.getByLabel("Title").fill("Test 3");
    const week = dashboard.container.getByLabel("Test week");
    const lastWeek = await week.getByRole("option").first().getAttribute("value") ?? "";
    await expect(week).not.toHaveValue(lastWeek);
    await week.selectOption(lastWeek);
    await dashboard.container.getByRole("button", { name: "Save" }).click();
    await expect(dashboard.dashboard.getByRole("heading", { name: "Test 3" })).toBeVisible();
    await dashboard.pane.getByLabel("Max Points").fill("10");
    await dashboard.pane.getByRole("button", { name: "Add Task" }).click();
    await expect(dashboard.tasks).toHaveText([/10 pts/]);

    // the tutor enters the points straight away
    await tutor.page.goto(`/lectures/${lecture.id}/tutorials`);
    const row = tutor.page.getByRole("table").getByRole("row", { name: studentName });
    await row.getByRole("spinbutton", { name: `Task 1 for ${studentName}` }).fill("7");
    await row.getByRole("button", { name: "Save this row's points" }).click();
    await expect(row.getByText("Reviewed")).toBeVisible();
  });

  /**
   * A lecture may judge its tests apart from the homework. The teacher says so
   * below the tests and is asked first, and from then on the student reads two
   * sums where there was one.
   */
  test("is taken out of the points total once the teacher says so", async ({
    factory,
    teacher,
    student,
  }) => {
    const lecture = await factory.create("lecture", ["released_for_all"], {
      teacher_id: teacher.user.id,
    });
    const tutorial = await factory.create("tutorial", [], {
      lecture_id: lecture.id, title: "Monday group",
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

    // a sheet and a test, each marked with 3.5 of 8 points
    for (const [title, kind] of [["Homework 1", "homework"], ["Test 1", "test"]]) {
      const assignment = await factory.create("assignment", ["expired"], {
        lecture_id: lecture.id, title, kind,
      });
      const book = await assignment.__call("assessment");
      await factory.create("assessment_participation", ["marked"], {
        assessment_id: book.id, user_id: student.user.id,
      });
    }

    // one sum over both, which is how a lecture starts out
    await student.page.goto(`/lectures/${lecture.id}/submissions`);
    const standing = student.page
      .getByRole("complementary", { name: "Exam admission" });
    await expect(standing.getByText("of 16 points possible so far")).toBeVisible();

    // a question that is dismissed leaves the box ticked
    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.gotoOverview();
    const box = teacher.page.getByLabel("Test points count towards the points total");
    await expect(box).toBeChecked();
    await box.uncheck();
    const dialog = teacher.page
      .getByRole("dialog", { name: "Take the tests out of the points total" });
    await expect(dialog).toBeVisible();
    await dialog.getByRole("button", { name: "Cancel" }).click();
    await expect(box).toBeChecked();

    // answered, it goes through; the overview lives in a Turbo frame, so the
    // round trip is what there is to wait for
    await box.uncheck();
    const saved = teacher.page.waitForResponse(
      r => r.request().method() === "POST",
    );
    await dialog.getByRole("button", { name: "Take out" }).click();
    await saved;
    await dashboard.gotoOverview();
    await expect(teacher.page.getByLabel("Test points count towards the points total"))
      .not.toBeChecked();

    // the student now reads the sheets' sum, and the tests' beside it
    await student.page.reload();
    await expect(
      standing.getByText("of 8 points possible so far from the homework sheets"),
    ).toBeVisible();
    await expect(standing.getByText("Tests: 3.5 of 8 points possible so far"))
      .toBeVisible();
  });

  /**
   * A test may be passed or failed, and the rule may ask for a number of
   * passed tests. The teacher sets both up; the student reads where they
   * stand.
   */
  test("is passed from its threshold on, and the rule can ask for passed tests", async ({
    factory,
    teacher,
    tutor,
    student,
  }) => {
    const lecture = await createEligibilityLecture(factory, teacher.user.id);
    const tutorial = await factory.create("tutorial", ["with_tutor_by_id"], {
      lecture_id: lecture.id, tutor_id: tutor.user.id, title: "Monday group",
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

    // a test the student has 3.5 of 8 points on
    const written = await factory.create("assignment", ["expired"], {
      lecture_id: lecture.id, title: "Test 1", kind: "test",
    });
    const book = await written.__call("assessment");
    await factory.create("assessment_participation", ["marked"], {
      assessment_id: book.id, user_id: student.user.id,
    });

    // the teacher gives the test a threshold, and the overview lists it
    const dashboard = new AssessmentDashboardPage(teacher.page, lecture.id);
    await dashboard.open("Test 1");
    await dashboard.pane.getByLabel("Passing threshold").fill("3");
    await dashboard.saveButton.click();
    await expect(teacher.page.getByText("Assessment updated successfully."))
      .toBeVisible();
    await dashboard.gotoOverview();
    await expect(teacher.page.getByRole("columnheader", { name: "Passing threshold" }))
      .toBeVisible();
    await expect(teacher.page.getByRole("cell", { name: "3 pts", exact: true }))
      .toBeVisible();

    // the tutor reads the threshold above the table and the verdict in the row
    await tutor.page.goto(`/lectures/${lecture.id}/tutorials`);
    await expect(tutor.page.getByText("passing threshold 3 pts · 1 passed · 0 not passed"))
      .toBeVisible();
    const row = tutor.page.getByRole("table")
      .getByRole("row", { name: student.user.name_in_tutorials });
    await expect(row.getByText("passed", { exact: true })).toBeVisible();

    // the rule asks for one passed test and for nothing else; asking for
    // more than can be passed is warned about while it is typed
    await dashboard.overviewTab("Exam Eligibility").click();
    await teacher.page.getByRole("link", { name: "Set up rule" }).click();
    await teacher.page.getByRole("radio", { name: "No point threshold" }).check();
    const warning = teacher.page
      .getByText("asks for more passed tests than currently carry a passing threshold");
    await teacher.page.getByLabel("at least").fill("2");
    await expect(warning).toBeVisible();
    await teacher.page.getByLabel("at least").fill("1");
    await expect(warning).toBeHidden();
    await teacher.page.getByRole("button", { name: "Save Rule" }).click();
    await expect(teacher.page.getByText("Eligibility rule updated.")).toBeVisible();
    await expect(
      teacher.page.getByText("passed test required (of 1 with a passing threshold)"),
    ).toBeVisible();

    // a test still to come says on its card what it takes to pass it
    await factory.create("assignment", [], {
      lecture_id: lecture.id, title: "Test 2", kind: "test", passing_points: 4,
    });

    // the student reads the result on the test and in the admission block
    await student.page.goto(`/lectures/${lecture.id}/submissions`);
    await expect(student.page.getByText("4 points needed to pass")).toBeVisible();
    const standing = student.page
      .getByRole("complementary", { name: "Exam admission" });
    await expect(standing.getByText("1 of 1 test passed so far")).toBeVisible();
    await expect(standing.getByText("At least 1 test passed")).toBeVisible();
    await expect(standing.getByText("You have 1 of 1 so far")).toBeVisible();
    await expect(student.page.getByText("passed · 3 points needed to pass"))
      .toBeVisible();
  });
});
