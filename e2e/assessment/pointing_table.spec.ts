import { expect, test } from "../_support/fixtures";
import { addTask, createAssessedAssignment } from "./helpers";

/**
 * A sheet that came in on paper leaves no file behind, so the tutor says so
 * in the table. The answer swaps the row alone; the table around it has to
 * keep the group's shape.
 */
test.describe("pointing table", () => {
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

    await row.getByRole("link", { name: "Record a hand-in on paper" }).click();
    await expect(row.getByText("Pending Grading")).toBeVisible();
    await expect(row.getByRole("spinbutton")).toBeEnabled();

    await row.getByRole("link", { name: "Take the paper hand-in back" }).click();
    await expect(row.getByText("Not Submitted")).toBeVisible();
    await expect(row.getByRole("spinbutton")).toBeDisabled();

    // still the group's table, not the lecture's with a group column
    await expect(table.getByRole("columnheader", { name: "Tutorial" })).toHaveCount(0);
    await expect(table.getByRole("row", { name: /Ada Lovelace/ })).toHaveCount(1);
  });

  test("records a pile of paper sheets in one go", async ({
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
    for (const name of ["Ada Lovelace", "Grace Hopper", "Emmy Noether"]) {
      const student = await factory.create("confirmed_user", [], {
        name_in_tutorials: name,
      });
      await factory.create("lecture_membership", [], {
        lecture_id: lecture.id, user_id: student.id,
      });
      await factory.create("tutorial_membership", [], {
        tutorial_id: tutorial.id, user_id: student.id,
      });
    }

    await tutor.page.goto(
      `/lectures/${lecture.id}/tutorials?assignment=${assignment.id}&tutorial=${tutorial.id}`,
    );
    const table = tutor.page.getByRole("table");
    const button = tutor.page.getByRole("button", {
      name: "Record selected as handed in on paper",
    });
    await expect(button).toBeDisabled();

    await table.getByRole("checkbox", { name: "Select Ada Lovelace for a hand-in on paper" })
      .check();
    await table.getByRole("checkbox", { name: "Select Emmy Noether for a hand-in on paper" })
      .check();
    await button.click();

    await expect(table.getByRole("row", { name: /Ada Lovelace/ }).getByText("Pending Grading"))
      .toBeVisible();
    await expect(table.getByRole("row", { name: /Emmy Noether/ }).getByText("Pending Grading"))
      .toBeVisible();
    await expect(table.getByRole("row", { name: /Grace Hopper/ }).getByText("Not Submitted"))
      .toBeVisible();
    await expect(button).toBeDisabled();
  });
});
