import FactoryBot from "../support/factorybot";
import Timecop from "../support/timecop";

function subscribeToLecture(lectureId) {
  cy.visit(`/lectures/${lectureId}/subscribe`);
  cy.getBySelector("subscribe-to-lecture").click();
  cy.getBySelector("subscribe-to-lecture").should("not.exist");
}

describe("Submissions Joining", () => {
  beforeEach(function () {
    Timecop.reset();

    cy.createUser("joiner").as("joiner");
    cy.createUser("inviter").as("inviter");
    cy.createUser("inviter2").as("inviter2");

    FactoryBot.create("lecture", "released_for_all").as("lecture");
    cy.then(() => {
      FactoryBot.create("tutorial", "with_tutors", { lecture_id: this.lecture.id }).as("tutorial");
      FactoryBot.create("assignment", { lecture_id: this.lecture.id }).as("assignment");
    });
  });

  // afterEach(() => {
  //   Timecop.reset();
  // });

  function createEmptySubmission(lectureId, inviteName = "") {
    cy.visit(`/lectures/${lectureId}/submissions`);
    cy.getBySelector("create-submission").click();
    if (inviteName) {
      cy.getBySelector("submission-invites").then(($wrapperDiv) => {
        cy.wrap($wrapperDiv).selectTom(inviteName);
      });
    }
    cy.getBySelector("save-submission").click();
    cy.getBySelector("submission-token").invoke("text").then((tokenRaw) => {
      const token = tokenRaw.trim();
      cy.wrap(token).as("token");
    });
  }

  function joinSubmissionViaToken(lectureId, token) {
    cy.visit(`/lectures/${lectureId}/submissions`);
    cy.getBySelector("submission-join").click();
    cy.getBySelector("submission-token-input").type(token);
    cy.getBySelector("submission-join-via-code").click();
    cy.getBySelector("submission-leave").should("be.visible");
  }

  it("can join a submission via code & direct invite", function () {
    // 🎈 "Inviter" creates a submission & stores code
    cy.login(this.inviter).then(() => {
      subscribeToLecture(this.lecture.id);
      createEmptySubmission(this.lecture.id);
      cy.logout();
    });

    // 🐰 "Joiner" joins the submission using the code
    cy.login(this.joiner).then(() => {
      subscribeToLecture(this.lecture.id);
      joinSubmissionViaToken(this.lecture.id, this.token);
      cy.logout();
    });

    // New assignment
    Timecop.moveAheadDays(1000).then(() => {
      FactoryBot.create("assignment", { lecture_id: this.lecture.id }).as("assignment");

      // 🎈🎈 "Inviter2" creates a submission & stores code
      cy.login(this.inviter2).then(() => {
        subscribeToLecture(this.lecture.id);
        createEmptySubmission(this.lecture.id);
        cy.logout();
      });

      // 🐰 "Joiner" joins the submission using the code
      cy.login(this.joiner).then(() => {
        joinSubmissionViaToken(this.lecture.id, this.token);
        cy.logout();
      });
    });

    // New assignment
    Timecop.moveAheadDays(2000).then(() => {
      FactoryBot.create("assignment", { lecture_id: this.lecture.id }).as("assignment");

      // 🎈 "Inviter" invites "Joiner" to a new submission
      cy.login(this.inviter).then(() => {
        // The "Joiner" name is not prefilled here since for the last assignment
        // "Inviter" did not submit anything (only "Inviter2" did)
        createEmptySubmission(this.lecture.id, this.joiner.name_in_tutorials);
        cy.logout();
      });

      // 🎈🎈 "Inviter2" invites "Joiner" to a new submission
      cy.login(this.inviter2).then(() => {
        createEmptySubmission(this.lecture.id);
        cy.logout();
      });

      // 🐰 "Joiner" can now join without a code
      // (since this user has previously handed in a submission together
      // with the inviter, see above)
      cy.login(this.joiner).then(() => {
        cy.visit(`/lectures/${this.tutorial.lecture_id}/submissions`);
        cy.getBySelector("submission-join").click();
        // cy.getBySelector("accept-invite").click();
        // cy.getBySelector("submission-leave").should("be.visible");
      });
    });
  });
});
