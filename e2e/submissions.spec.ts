import { expect, test } from "./_support/fixtures";
import { LecturePage } from "./page-objects/lecture_page";
// import { User } from "./_support/auth";
import { SubmissionsPage } from "./page-objects/submissions_page";

test("can join a submission via code & direct invite",
  async ({ factory, timeCop, student: inviter, student2: inviter2, student3: joiner }) => {
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

    await timeCop.moveAheadDays(1000);
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

    await timeCop.moveAheadDays(2000);
    // New assignment
    await factory.create("assignment", [], { lecture_id: lecture.id });
    // 🎈 "Inviter" invites "Joiner" to a new submission
    await submissionsInviter.goto();
    await submissionsInviter.createSubmission(joiner.user.name_in_tutorials);
    // The "Joiner" name is not prefilled here since for the last assignment
    // "Inviter" did not submit anything (only "Inviter2" did)

    // 🎈🎈 "Inviter2" invites "Joiner" to a new submission
    await submissionsInviter2.goto();
    await submissionsInviter2.createSubmission();

    // 🐰 "Joiner" can now join without a code
    // (since this user has previously handed in a submission together with the inviter, see above)
    await joiner.page.waitForLoadState("networkidle");
    await joiner.page.reload(); 

    await submissionsJoiner.acceptSubmissionInviteFrom(inviter.user.name_in_tutorials);
    
    await joiner.page.waitForLoadState("networkidle"); 
    await joiner.page.reload();
    await expect(submissionsJoiner.currentSubmissionTeam()).toContainText(inviter.user.name_in_tutorials);
    
    // only one invite left
    await joiner.page.waitForLoadState("networkidle");
    await joiner.page.reload();
    
    joiner.page.once("dialog", dialog => dialog.accept());
    await joiner.page.getByTestId("current-submissions").getByRole("button", { name: "leave" }).click();
    await submissionsJoiner.goto();
    joiner.page.once("dialog", dialog => dialog.accept());  

    await joiner.page.waitForLoadState("networkidle");
    await joiner.page.reload();

    await joiner.page.getByRole("button", { name: "join" }).click();
    await expect(joiner.page.locator(".alert", { hasText: inviter2.user.name_in_tutorials })).toBeVisible();
    await expect(joiner.page.locator(".alert", { hasText: inviter.user.name_in_tutorials })).toBeHidden();
    await joiner.page.getByTestId("submission-cancel-join").click();

    await submissionsJoiner.acceptSubmissionInviteFrom(inviter2.user.name_in_tutorials);
    await expect(submissionsJoiner.currentSubmissionTeam()).toContainText(inviter2.user.name_in_tutorials);
  });   

  test("does not show invite when assignment is overdue (also check grace period)",
    async ({ factory, timeCop, student: inviter, student3: joiner }) => {
      const lecture = await factory.create("lecture", ["released_for_all"]);
      await factory.create("tutorial", ["with_tutors"], { lecture_id: lecture.id });
      await factory.create("assignment", [], { lecture_id: lecture.id });

      const currentSubmissions = joiner.page.getByTestId("current-submissions");
      const previousSubmissions = joiner.page.getByTestId("previous-submissions");

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
      
      await timeCop.moveAheadDays(100);
      // New assignment
      const assignment = await factory.create("assignment", [], { lecture_id: lecture.id });
      // 🎈 "Inviter" invites "Joiner" to a new submission  
      await submissionsInviter.goto();
      await submissionsInviter.createSubmission(); // joiner should be prefilled here, no need to call them specifically

      // During grace period
      const deadline = new Date(assignment.deadline);
      const gracePeriodMinutes = lecture.submission_grace_period;

      const duringGracePeriodMinutes = Math.floor(Math.random() * (gracePeriodMinutes - 1)) + 1;
      const travelDate = new Date(deadline);
      travelDate.setMinutes(travelDate.getMinutes() + duringGracePeriodMinutes);
      await timeCop.travelToDate(travelDate);

      // 🐰 "Joiner" should still see the invite button, even if the assignment
      // is overdue, if we are still in the "grace period".
      await submissionsJoiner.goto();
      // assignment title of current submission and invite accept button should be visible
      await expect(currentSubmissions.getByRole("heading", { name: assignment.title })).toBeVisible();
      await expect(joiner.page.locator(".alert", { hasText: inviter.user.name_in_tutorials })).toBeVisible();


      // After grace period
      const newTravelDate = new Date(deadline);
      newTravelDate.setMinutes(newTravelDate.getMinutes() + gracePeriodMinutes + 100);
      await expect(currentSubmissions.getByRole("heading", { name: assignment.title })).toBeVisible();
      await timeCop.travelToDate(newTravelDate);
      
      await joiner.page.reload();
      await joiner.page.waitForLoadState("networkidle");

      // 🐰 "Joiner" should not be able to join via an invite now
      // as the assignment is overdue (deadline is in the past and "grace period"
      // is over).
      await submissionsJoiner.goto();
      await expect(previousSubmissions.getByRole("heading", { name: assignment.title })).toBeVisible();
      await expect(currentSubmissions.getByRole("heading", { name: assignment.title })).toBeHidden();
      await expect(joiner.page.locator(".alert", { hasText: inviter.user.name_in_tutorials })).toBeHidden();

    }
  );
