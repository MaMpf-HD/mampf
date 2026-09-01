import { expect, test } from "../_support/fixtures";
import { FactoryBot, FactoryBotObject } from "../_support/factorybot";
import { resetClock, travelTo } from "../_support/timecop";
import { SubmissionsPage } from "../page-objects/submissions_page";

/**
 * The card for the sheet that is still open: handing in, replacing the file,
 * inviting somebody, joining a team and leaving it again. Each of those changes
 * this one sheet, so each is answered by the card's own Turbo frame - the page
 * around it never moves.
 */
test.describe("the card for a sheet that is due", () => {
  async function lectureWithSheet(
    factory: FactoryBot,
    teacherId: number,
    studentIds: number[],
    title = "Homework 1",
  ): Promise<{ lecture: FactoryBotObject; assignment: FactoryBotObject }> {
    const lecture = await factory.create("lecture", ["released_for_all"], {
      teacher_id: teacherId,
      locale: "en",
    });
    const tutorial = await factory.create("tutorial", [], {
      lecture_id: lecture.id,
      title: "Monday group",
    });
    for (const id of studentIds) {
      await factory.create("lecture_user_join", [], {
        lecture_id: lecture.id, user_id: id,
      });
      await factory.create("tutorial_membership", [], {
        tutorial_id: tutorial.id, user_id: id,
      });
    }
    // Pinned rather than left to the factory, whose default deadline is a random
    // day within a month: which sheet counts as the current one decides what the
    // form offers as a past partner.
    const assignment = await factory.create("assignment", [], {
      lecture_id: lecture.id,
      title,
      deadline: new Date(Date.now() + 7 * 86400000).toISOString(),
    });
    return { lecture, assignment };
  }

  test("hands a sheet in and shows the file on the card", async ({
    factory,
    teacher,
    student,
  }) => {
    const { lecture } = await lectureWithSheet(
      factory, teacher.user.id, [student.user.id],
    );

    const page = new SubmissionsPage(student.page, lecture.id);
    await page.goto();
    await expect(student.page.getByText("Nothing handed in yet")).toBeVisible();

    await page.createSubmission();

    await expect(student.page.getByText("Handed in", { exact: true }))
      .toBeVisible();
    await expect(student.page.getByRole("link", { name: "manuscript.pdf" }))
      .toBeVisible();
    // The list is for sheets that are behind you; this one is still open, so it
    // has a card and no row.
    await expect(
      student.page.getByRole("region", { name: "Earlier sheets" })
        .getByText("None yet"),
    ).toBeVisible();
  });

  test("replaces the file without leaving the page", async ({
    factory,
    teacher,
    student,
  }) => {
    const { lecture } = await lectureWithSheet(
      factory, teacher.user.id, [student.user.id],
    );

    const page = new SubmissionsPage(student.page, lecture.id);
    await page.goto();
    await page.createSubmission();

    await student.page.getByRole("link", { name: "Replace file" }).click();
    await page.uploadSubmission("e2e/files/manuscript-mampfsty.pdf");
    await student.page.getByRole("button", { name: "Save" }).click();

    await expect(student.page.getByRole("link", { name: "manuscript-mampfsty.pdf" }))
      .toBeVisible();
  });

  // Inviting by name is offered only to people one has handed in with before -
  // the first team-up always goes through the code. So this walks both: the
  // code once, then the invitation it unlocks on the next sheet.
  test("invites a past partner, who accepts and later leaves", async ({
    factory,
    teacher,
    student,
    student2,
  }) => {
    // Two people, two sheets and two uploads: the longest walk in this file.
    test.slow();
    const { lecture } = await lectureWithSheet(
      factory, teacher.user.id, [student.user.id, student2.user.id],
    );
    await factory.create("assignment", [], {
      lecture_id: lecture.id,
      title: "Homework 2",
      deadline: new Date(Date.now() + 14 * 86400000).toISOString(),
    });

    const page = new SubmissionsPage(student.page, lecture.id);
    await page.goto();
    const first = student.page.getByRole("region", { name: "Homework 1" });
    await first.getByRole("link", { name: "Hand in" }).click();
    await page.uploadSubmission();
    await student.page.getByRole("button", { name: "Save" }).click();
    await expect(first.getByRole("link", { name: "Replace file" })).toBeVisible();
    const code = await first.locator("code").innerText();

    await student2.page.goto(`/lectures/${lecture.id}/submissions`);
    const joined = student2.page.getByRole("region", { name: "Homework 1" });
    await joined.getByRole("link", { name: "Join with a code" }).click();
    await student2.page.getByRole("textbox", { name: "Code" }).fill(code);
    await student2.page.getByRole("button", { name: "Join" }).click();
    await expect(joined.getByText(student.user.name_in_tutorials)).toBeVisible();

    // Now they are partners, so the second sheet can be shared by name while it
    // is handed in.
    await student.page.reload();
    const second = student.page.getByRole("region", { name: "Homework 2" });
    await second.getByRole("link", { name: "Hand in" }).click();
    // The form offers everybody one has handed in with before and preselects the
    // most recent of them, so the invitation rides along with the hand-in. That
    // preselection is the thing to check; driving the picker by hand would test
    // the widget, not the page.
    await expect(student.page.locator("#submission_invitee_ids"))
      .toHaveValues([`${student2.user.id}`]);
    await page.uploadSubmission();
    const handedIn = student.page.waitForResponse(
      response => response.request().method() === "POST",
    );
    await student.page.getByRole("button", { name: "Save" }).click();
    await handedIn;
    await expect(second.getByRole("link", { name: "Replace file" })).toBeVisible();

    // The invitation carries the code, so accepting it is one button.
    await student2.page.goto(`/lectures/${lecture.id}/submissions`);
    const invited = student2.page.getByRole("region", { name: "Homework 2" });
    await invited.getByRole("button", { name: "Accept invitation" }).click();
    await expect(invited.getByText(student.user.name_in_tutorials)).toBeVisible();

    student2.page.once("dialog", dialog => dialog.accept());
    await invited.getByRole("link", { name: "Leave the team" }).click();
    await expect(invited.getByText("Nothing handed in yet")).toBeVisible();
  });

  test("joins with a code that was passed on", async ({
    factory,
    teacher,
    student,
    student2,
  }) => {
    const { lecture, assignment } = await lectureWithSheet(
      factory, teacher.user.id, [student.user.id, student2.user.id],
    );

    const page = new SubmissionsPage(student.page, lecture.id);
    await page.goto();
    await page.createSubmission();
    const code = await student.page.locator("code").innerText();

    await student2.page.goto(`/lectures/${lecture.id}/submissions`);
    await student2.page.getByRole("link", { name: "Join with a code" }).click();
    await student2.page.getByRole("textbox", { name: "Code" }).fill(code);
    await student2.page.getByRole("button", { name: "Join" }).click();

    await expect(student2.page.getByText(student.user.name_in_tutorials))
      .toBeVisible();
    expect(assignment.id).toBeTruthy();
  });

  // The message belongs beside the field the reader typed in, not in an alert
  // box that leaves the form behind.
  test("says so in the form when the code is wrong", async ({
    factory,
    teacher,
    student,
  }) => {
    const { lecture } = await lectureWithSheet(
      factory, teacher.user.id, [student.user.id],
    );

    await student.page.goto(`/lectures/${lecture.id}/submissions`);
    await student.page.getByRole("link", { name: "Join with a code" }).click();
    await student.page.getByRole("textbox", { name: "Code" }).fill("NOPE42");
    await student.page.getByRole("button", { name: "Join" }).click();

    await expect(student.page.getByText("The code you entered is invalid"))
      .toBeVisible();
    await expect(student.page.getByRole("textbox", { name: "Code" }))
      .toBeVisible();
  });

  test("deletes a hand-in the reader made alone", async ({
    factory,
    teacher,
    student,
  }) => {
    const { lecture } = await lectureWithSheet(
      factory, teacher.user.id, [student.user.id],
    );

    const page = new SubmissionsPage(student.page, lecture.id);
    await page.goto();
    await page.createSubmission();

    student.page.once("dialog", dialog => dialog.accept());
    await student.page.getByRole("link", { name: "Delete" }).click();

    await expect(student.page.getByText("Nothing handed in yet")).toBeVisible();
    await expect(student.page.getByRole("link", { name: "manuscript.pdf" }))
      .toHaveCount(0);
  });

  // Past the deadline the card still stands, and it says how long is left.
  test("counts the grace period down on the card", async ({
    factory,
    teacher,
    student,
  }) => {
    const { lecture, assignment } = await lectureWithSheet(
      factory, teacher.user.id, [student.user.id],
    );
    const deadline = new Date(await assignment.__call("deadline") as string);
    const inGrace = new Date(deadline.getTime() + 5 * 60 * 1000);

    try {
      await travelTo(student.page.context().request, inGrace);
      await student.page.goto(`/lectures/${lecture.id}/submissions`);

      await expect(student.page.getByText("left", { exact: false }).first())
        .toBeVisible();
      await expect(student.page.getByRole("link", { name: "Hand in" }))
        .toBeVisible();
    }
    finally {
      await resetClock(student.page.context().request);
    }
  });
});
