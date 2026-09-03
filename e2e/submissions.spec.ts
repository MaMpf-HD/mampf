import { expect, test } from "./_support/fixtures";
import { LecturePage } from "./page-objects/lecture_page";
// import { User } from "./_support/auth";
import { SubmissionsPage } from "./page-objects/submissions_page";

test("can join a submission via code & direct invite",
  async ({ factory, student: inviter, student2: inviter2, student3: joiner }) => {
    // test code goes here
    const lecture = await factory.create("lecture", ["released_for_all"]);
    await factory.create("tutorial", ["with_tutors"], { lecture_id: lecture.id });
    await factory.create("assignment", [], { lecture_id: lecture.id });

    // 🎈 "Inviter" creates a submission & stores code
    const lecturePageInviter = new LecturePage(inviter.page, lecture.id);
    await lecturePageInviter.subscribe();

    const submissionsInviter = new SubmissionsPage(inviter.page, lecture.id);
    await submissionsInviter.goto();

    const token = await submissionsInviter.createSubmission();

    // 🐰 "Joiner" joins the submission using the code
    const lecturePageJoiner = new LecturePage(joiner.page, lecture.id);
    await lecturePageJoiner.subscribe();

    const submissionsJoiner = new SubmissionsPage(joiner.page, lecture.id);
    await submissionsJoiner.goto();

    await submissionsJoiner.joinSubmission(token);

    // New assignment
    await factory.create("assignment", [], { lecture_id: lecture.id });
    // 🎈🎈 "Inviter2" creates a submission & stores code
    const lecturePageInviter2 = new LecturePage(inviter2.page, lecture.id);
    await lecturePageInviter2.subscribe();

    const submissionsInviter2 = new SubmissionsPage(inviter2.page, lecture.id);
    await submissionsInviter2.goto();

    const token2 = await submissionsInviter2.createSubmission();

    // 🐰 "Joiner" joins the submission using the code
    await submissionsJoiner.goto();
    await submissionsJoiner.joinSubmission(token2);

    // New assignment
    await factory.create("assignment", [], { lecture_id: lecture.id });
    // 🎈 "Inviter" invites "Joiner" to a new submission
    await submissionsInviter.goto();
    await submissionsInviter.createSubmission();
    // The "Joiner" name is not prefilled here since for the last assignment
    // "Inviter" did not submit anything (only "Inviter2" did)

    // 🎈🎈 "Inviter2" invites "Joiner" to a new submission
    await submissionsInviter2.goto();
    await submissionsInviter2.createSubmission();

    // 🐰 "Joiner" can now join without a code
    // (since this user has previously handed in a submission together with the inviter, see above)
    await submissionsJoiner.goto();
    await submissionsJoiner.acceptSubmissionInvite(0);
    // now there is only one invite left (that from "Inviter2")
    await expect(joiner.page.getByTestId("submission-team")).toContainText(inviter.user.name_in_tutorials);
    await joiner.page.getByRole("button", { name: "leave" }).click();

    // only one invite left
    await submissionsJoiner.goto();
    await joiner.page.getByRole("button", { name: "join" }).click();
    await expect(joiner.page.getByTestId("accept-invite-1")).toBeHidden();
    await expect(joiner.page.getByTestId("accept-invite-0")).toBeVisible();
    await joiner.page.getByTestId("submission-cancel-join").click();

    await joiner.page.getByTestId("accept-invite-0").click();
    await expect(joiner.page.getByTestId("submisions-team")).toContainText(inviter2.user.name_in_tutorials);
  });

// test("does not show invite when assignment is overdue (also check grace period)",
// test code goes here

// 🎈 "Inviter" creates a submission & stores code
// 🐰 "Joiner" joins the submission using the code

// New assignment
// 🎈 "Inviter" invites "Joiner" to a new submission
// During grace period
// 🐰 "Joiner" should still see the invite button, even if the assignment
// is overdue, if we are still in the "grace period".
// After grace period
// 🐰 "Joiner" should not be able to join via an invite now
// as the assignment is overdue (deadline is in the past and "grace period"
// is over).
// );