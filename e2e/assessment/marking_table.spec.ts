import { expect, test } from "../_support/fixtures";
import {
  addTask, createAssessedAssignment, createLegacyAssignment, scoreTask,
} from "./helpers";

async function handIn(
  factory: Parameters<typeof createAssessedAssignment>[0],
  assignmentId: number,
  tutorialId: number,
  userId: number,
) {
  // handed in two days ago, so it is in time for a sheet that expired yesterday
  const submission = await factory.create("submission", ["with_manuscript"], {
    assignment_id: assignmentId,
    tutorial_id: tutorialId,
    last_modification_by_users_at: new Date(Date.now() - 2 * 86400000).toISOString(),
  });
  await factory.create("user_submission_join", [], {
    submission_id: submission.id, user_id: userId,
  });
  return submission;
}

test.describe("marking table", () => {
  test("records a hand-in on paper and takes it back", async ({
    factory,
    teacher,
    tutor,
  }) => {
    const { lecture, assignment, assessmentId } = await createAssessedAssignment(
      factory, teacher.user.id, "Problem Set 1", ["expired"],
    );
    await addTask(factory, assessmentId, "Warm-up", 10);
    const tutorial = await factory.create("tutorial", ["with_tutor_by_id"], {
      lecture_id: lecture.id,
      tutor_id: tutor.user.id,
      title: "Tuesday group",
    });
    const student = await factory.create("confirmed_user", [], {
      name_in_tutorials: "Ada Lovelace",
    });
    await factory.create("lecture_membership", [], {
      lecture_id: lecture.id, user_id: student.id,
    });
    await factory.create("tutorial_membership", [], {
      tutorial_id: tutorial.id, user_id: student.id,
    });

    await tutor.page.goto(
      `/lectures/${lecture.id}/tutorials?assignment=${assignment.id}&tutorial=${tutorial.id}`,
    );
    const table = tutor.page.getByRole("table");
    const row = table.getByRole("row", { name: /Ada Lovelace/ });
    await expect(row.getByText("Not Submitted")).toBeVisible();
    await expect(row.getByRole("spinbutton")).toBeDisabled();

    await row.getByRole("link", { name: "Record a hand-in on paper or by other means" }).click();
    await expect(row.getByText("Pending Grading")).toBeVisible();
    await expect(row.getByRole("spinbutton")).toBeEnabled();

    await row.getByRole("link", { name: "Take the hand-in record back" }).click();
    await expect(row.getByText("Not Submitted")).toBeVisible();
    await expect(row.getByRole("spinbutton")).toBeDisabled();

    // still the group's table, not the lecture's with a group column
    await expect(table.getByRole("columnheader", { name: "Tutorial" })).toHaveCount(0);
    await expect(table.getByRole("row", { name: /Ada Lovelace/ })).toHaveCount(1);
  });

  // Somebody forgot to join their team's upload; the tutor puts them on it,
  // and the points the team already has come along.
  test("puts a member who forgot to join onto the team, with its points", async ({
    factory,
    teacher,
    tutor,
  }) => {
    const { lecture, assignment, assessmentId } = await createAssessedAssignment(
      factory, teacher.user.id, "Problem Set 1", ["expired"],
    );
    const task = await addTask(factory, assessmentId, "Warm-up", 10);
    const tutorial = await factory.create("tutorial", ["with_tutor_by_id"], {
      lecture_id: lecture.id, tutor_id: tutor.user.id, title: "Tuesday group",
    });
    const members = [];
    for (const name of ["Ada Lovelace", "Grace Hopper"]) {
      const student = await factory.create("confirmed_user", [], { name_in_tutorials: name });
      await factory.create("lecture_membership", [], { lecture_id: lecture.id, user_id: student.id });
      await factory.create("tutorial_membership", [], {
        tutorial_id: tutorial.id, user_id: student.id,
      });
      members.push(student);
    }
    const [ada] = members;
    await handIn(factory, assignment.id, tutorial.id, ada.id);
    const adaRow = await factory.create("assessment_participation", [], {
      assessment_id: assessmentId, user_id: ada.id, tutorial_id: tutorial.id,
      submitted_at: new Date(Date.now() - 2 * 86400000).toISOString(),
    });
    await scoreTask(factory, task.id, adaRow.id, 7);

    await tutor.page.goto(
      `/lectures/${lecture.id}/tutorials?assignment=${assignment.id}&tutorial=${tutorial.id}`,
    );
    const table = tutor.page.getByRole("table");
    await expect(table.getByRole("row", { name: /Grace Hopper/ }).getByText("Not Submitted"))
      .toBeVisible();

    const teamRow = table.getByRole("row", { name: /Ada Lovelace/ });
    await teamRow.getByRole("button", { name: "Put somebody on this team" }).click();
    await teamRow.getByRole("button", { name: "Grace Hopper" }).click();

    await expect(tutor.page.getByText("Grace Hopper is on the team now.")).toBeVisible();
    const joined = table.getByRole("row", { name: /Ada Lovelace/ });
    await expect(joined).toContainText("Grace Hopper");
    await expect(table.getByRole("row", { name: /Grace Hopper/ })).toHaveCount(1);
    await expect(joined.getByRole("spinbutton", { name: /Task 1 for Ada Lovelace/ }))
      .toHaveValue("7.0");
  });

  test("says where the sheet stands and narrows the rows", async ({
    factory,
    teacher,
    tutor,
  }) => {
    const { lecture, assignment, assessmentId } = await createAssessedAssignment(
      factory, teacher.user.id, "Problem Set 1", ["expired"],
    );
    const task = await addTask(factory, assessmentId, "Warm-up", 10);
    const tutorial = await factory.create("tutorial", ["with_tutor_by_id"], {
      lecture_id: lecture.id,
      tutor_id: tutor.user.id,
    });
    const students = [];
    for (const name of ["Ada Lovelace", "Grace Hopper"]) {
      const student = await factory.create("confirmed_user", [], {
        name_in_tutorials: name,
      });
      await factory.create("lecture_membership", [], {
        lecture_id: lecture.id, user_id: student.id,
      });
      await factory.create("tutorial_membership", [], {
        tutorial_id: tutorial.id, user_id: student.id,
      });
      students.push(student);
    }
    const marked = await factory.create("assessment_participation", [], {
      assessment_id: assessmentId,
      user_id: students[0].id,
      tutorial_id: tutorial.id,
      status: "reviewed",
      submitted_at: new Date().toISOString(),
    });
    await scoreTask(factory, task.id, marked.id, 7);

    await tutor.page.goto(
      `/lectures/${lecture.id}/tutorials?assignment=${assignment.id}&tutorial=${tutorial.id}`,
    );
    await expect(tutor.page.getByText("1 hand-in · 1 reviewed · 1 not submitted")).toBeVisible();

    const table = tutor.page.getByRole("table");
    await tutor.page.getByLabel("Status").selectOption("Not Submitted");
    await expect(table.getByRole("row", { name: /Ada Lovelace/ })).toBeHidden();
    await expect(table.getByRole("row", { name: /Grace Hopper/ })).toBeVisible();
    await expect(tutor.page.getByText("1 of 2 rows")).toBeVisible();

    await tutor.page.getByLabel("Name").fill("Ada");
    await expect(tutor.page.getByText("No matching rows.")).toBeVisible();

    await tutor.page.getByRole("button", { name: "Reset filters" }).click();
    await expect(table.getByRole("row", { name: /Ada Lovelace/ })).toBeVisible();
    await expect(table.getByRole("row", { name: /Grace Hopper/ })).toBeVisible();
    await expect(tutor.page.getByText("No matching rows.")).toBeHidden();

    await tutor.page.getByLabel("Status").selectOption("Not Submitted");
    await table.getByRole("row", { name: /Grace Hopper/ })
      .getByRole("link", { name: "Record a hand-in on paper or by other means" }).click();
    await expect(table.getByRole("row", { name: /Grace Hopper/ })).toBeHidden();
    await expect(tutor.page.getByText("No matching rows.")).toBeVisible();
    await expect(tutor.page.getByText("2 hand-ins · 1 reviewed · 1 pending grading")).toBeVisible();
  });

  test("saves one row, then the rest at once", async ({ factory, teacher, tutor }) => {
    const { lecture, assignment, assessmentId } = await createAssessedAssignment(
      factory, teacher.user.id, "Problem Set 1", ["expired"],
    );
    await addTask(factory, assessmentId, "Warm-up", 10);
    const tutorial = await factory.create("tutorial", ["with_tutor_by_id"], {
      lecture_id: lecture.id,
      tutor_id: tutor.user.id,
    });
    for (const name of ["Ada Lovelace", "Grace Hopper"]) {
      const student = await factory.create("confirmed_user", [], {
        name_in_tutorials: name,
      });
      await factory.create("lecture_membership", [], {
        lecture_id: lecture.id, user_id: student.id,
      });
      await factory.create("tutorial_membership", [], {
        tutorial_id: tutorial.id, user_id: student.id,
      });
      await handIn(factory, assignment.id, tutorial.id, student.id);
    }

    await tutor.page.goto(
      `/lectures/${lecture.id}/tutorials?assignment=${assignment.id}&tutorial=${tutorial.id}`,
    );
    const table = tutor.page.getByRole("table");
    const ada = table.getByRole("row", { name: /Ada Lovelace/ });
    const grace = table.getByRole("row", { name: /Grace Hopper/ });
    const saveAll = tutor.page.getByRole("button", { name: /Save all changes/ });
    await expect(saveAll).toBeDisabled();

    await ada.getByRole("spinbutton", { name: "Task 1 for Ada Lovelace" }).fill("7");
    await expect(saveAll).toBeEnabled();
    await expect(saveAll).toContainText("1");
    await ada.getByRole("button", { name: "Save this row's points" }).click();
    await expect(ada.getByText("Reviewed")).toBeVisible();
    await expect(tutor.page.getByText("2 hand-ins · 1 reviewed · 1 pending grading")).toBeVisible();
    // the saved row left the pile of unsaved changes
    await expect(saveAll).toBeDisabled();

    await grace.getByRole("spinbutton", { name: "Task 1 for Grace Hopper" }).fill("4");
    await saveAll.click();
    await expect(grace.getByText("Reviewed")).toBeVisible();
    await expect(tutor.page.getByText("2 hand-ins · 2 reviewed")).toBeVisible();
    await expect(saveAll).toBeDisabled();
  });

  // Bonus points are allowed, so the table takes more than the maximum and
  // only says so.
  test("points a finger at more than the task's maximum, and still saves it", async ({
    factory,
    teacher,
    tutor,
  }) => {
    const { lecture, assignment, assessmentId } = await createAssessedAssignment(
      factory, teacher.user.id, "Problem Set 1", ["expired"],
    );
    await addTask(factory, assessmentId, "Warm-up", 10);
    const tutorial = await factory.create("tutorial", ["with_tutor_by_id"], {
      lecture_id: lecture.id,
      tutor_id: tutor.user.id,
    });
    const student = await factory.create("confirmed_user", [], {
      name_in_tutorials: "Ada Lovelace",
    });
    await factory.create("lecture_membership", [], {
      lecture_id: lecture.id, user_id: student.id,
    });
    await factory.create("tutorial_membership", [], {
      tutorial_id: tutorial.id, user_id: student.id,
    });
    await handIn(factory, assignment.id, tutorial.id, student.id);

    await tutor.page.goto(
      `/lectures/${lecture.id}/tutorials?assignment=${assignment.id}&tutorial=${tutorial.id}`,
    );
    const row = tutor.page.getByRole("row", { name: /Ada Lovelace/ });
    const points = row.getByRole("spinbutton", { name: "Task 1 for Ada Lovelace" });

    const amber = "rgb(255, 193, 7)";
    await points.fill("25");
    await expect(points).toHaveAttribute("title", "More than the task's 10 points");
    await expect(points).toHaveCSS("border-color", amber);

    await points.fill("5");
    await expect(points).toHaveAttribute("title", "");
    await expect(points).not.toHaveCSS("border-color", amber);

    // a value the browser refuses is not over the maximum either
    await points.fill("25");
    await expect(points).toHaveCSS("border-color", amber);
    await points.fill("-1");
    await expect(points).toHaveAttribute("title", "");
    await expect(points).not.toHaveCSS("border-color", amber);

    await points.fill("12");
    await row.getByRole("button", { name: "Save this row's points" }).click();
    await expect(row.getByText("Reviewed")).toBeVisible();
    await expect(points).toHaveValue("12.0");
    await expect(points).toHaveAttribute("title", "More than the task's 10 points");
  });

  // The two selects above the table are the tutor's way from one sheet or
  // group to the next; each option is a page.
  test("moves to another sheet and another group through the selects", async ({
    factory,
    teacher,
    tutor,
  }) => {
    const { lecture, assignment, assessmentId } = await createAssessedAssignment(
      factory, teacher.user.id, "Problem Set 1", ["expired"],
    );
    await addTask(factory, assessmentId, "Warm-up", 10);
    const second = await factory.create("assignment", ["expired"], {
      lecture_id: lecture.id,
      title: "Problem Set 2",
    });
    const monday = await factory.create("tutorial", ["with_tutor_by_id"], {
      lecture_id: lecture.id, tutor_id: tutor.user.id, title: "Monday group",
    });
    const friday = await factory.create("tutorial", ["with_tutor_by_id"], {
      lecture_id: lecture.id, tutor_id: tutor.user.id, title: "Friday group",
    });

    await tutor.page.goto(
      `/lectures/${lecture.id}/tutorials?assignment=${assignment.id}&tutorial=${monday.id}`,
    );

    await tutor.page.getByLabel("Assignment").selectOption({ label: "Problem Set 2" });
    await expect(tutor.page).toHaveURL(new RegExp(`assignment=${second.id}`));
    await expect(tutor.page.getByLabel("Assignment")).toHaveValue("Problem Set 2");

    await tutor.page.getByLabel("Tutorial").selectOption({ label: "Friday group" });
    await expect(tutor.page).toHaveURL(new RegExp(`tutorial=${friday.id}`));
    await expect(tutor.page.getByLabel("Tutorial")).toHaveValue("Friday group");
  });

  test("narrows a sheet from before there were points by name", async ({
    factory,
    teacher,
    tutor,
  }) => {
    const { lecture, assignment } = await createLegacyAssignment(
      factory, teacher.user.id, "Problem Set 0",
    );
    const tutorial = await factory.create("tutorial", ["with_tutor_by_id"], {
      lecture_id: lecture.id,
      tutor_id: tutor.user.id,
    });
    for (const name of ["Ada Lovelace", "Grace Hopper"]) {
      const student = await factory.create("confirmed_user", [], {
        name_in_tutorials: name,
      });
      await factory.create("lecture_membership", [], {
        lecture_id: lecture.id, user_id: student.id,
      });
      await factory.create("tutorial_membership", [], {
        tutorial_id: tutorial.id, user_id: student.id,
      });
      await handIn(factory, assignment.id, tutorial.id, student.id);
    }

    await tutor.page.goto(
      `/lectures/${lecture.id}/tutorials?assignment=${assignment.id}&tutorial=${tutorial.id}`,
    );
    const table = tutor.page.getByRole("table");
    await expect(table.getByRole("columnheader", { name: "Status" })).toHaveCount(0);
    await expect(tutor.page.getByLabel("Status")).toHaveCount(0);

    await tutor.page.getByLabel("Name").fill("Grace");
    await expect(table.getByRole("row", { name: /Ada Lovelace/ })).toBeHidden();
    await expect(table.getByRole("row", { name: /Grace Hopper/ })).toBeVisible();
    await expect(tutor.page.getByText("1 of 2 rows")).toBeVisible();

    await tutor.page.getByRole("button", { name: "Reset filters" }).click();
    await expect(table.getByRole("row", { name: /Ada Lovelace/ })).toBeVisible();
  });

  // From the first row the popup opens into the pinned header; behind the
  // header it is not there for the reader.
  test("keeps the copied-addresses note in front of the header", async ({
    factory,
    teacher,
    tutor,
  }) => {
    await tutor.page.context().grantPermissions(["clipboard-read", "clipboard-write"]);
    const { lecture, assignment, assessmentId } = await createAssessedAssignment(
      factory, teacher.user.id, "Problem Set 1", ["expired"],
    );
    await addTask(factory, assessmentId, "Warm-up", 10);
    const tutorial = await factory.create("tutorial", ["with_tutor_by_id"], {
      lecture_id: lecture.id,
      tutor_id: tutor.user.id,
    });
    const student = await factory.create("confirmed_user", [], {
      name_in_tutorials: "Ada Lovelace",
    });
    await factory.create("lecture_membership", [], {
      lecture_id: lecture.id, user_id: student.id,
    });
    await factory.create("tutorial_membership", [], {
      tutorial_id: tutorial.id, user_id: student.id,
    });
    await handIn(factory, assignment.id, tutorial.id, student.id);

    await tutor.page.goto(
      `/lectures/${lecture.id}/tutorials?assignment=${assignment.id}&tutorial=${tutorial.id}`,
    );
    const row = tutor.page.getByRole("row", { name: /Ada Lovelace/ });
    await row.getByRole("button", { name: "Copy mail adresses to Clipboard" }).click();

    const note = tutor.page.getByText("Mail adresses have been copied to the clipboard.");
    await expect(note).toBeVisible();
    // hover fails when another element would take the pointer instead
    await note.hover();
  });
});
