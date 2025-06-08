import FactoryBot from "../support/factorybot";
import Timecop from "../support/timecop";

function subscribeToLecture(lectureId) {
  cy.visit(`/lectures/${lectureId}/subscribe`);
  cy.getBySelector("subscribe-to-lecture").click();
}

describe("Submissions Joining", () => {
  beforeEach(function () {
    cy.createUser("joiner").as("joiner");
    cy.createUser("inviter").as("inviter");

    FactoryBot.create("lecture", "released_for_all").as("lecture");
    cy.then(() => {
      FactoryBot.create("tutorial", "with_tutors", { lecture_id: this.lecture.id }).as("tutorial");
      FactoryBot.create("assignment", { lecture_id: this.lecture.id }).as("assignment");
    });
  });

  afterEach(() => {
    Timecop.reset();
  });

  function createEmptySubmission(lectureId) {
    cy.visit(`/lectures/${lectureId}/submissions`);
    cy.getBySelector("create-submission").click();
    cy.getBySelector("save-submission").click();
    cy.getBySelector("submission-token").invoke("text").then((tokenRaw) => {
      const token = tokenRaw.trim();
      cy.wrap(token).as("token");
    });
  }

  it.only("can join a submission by direct invite", function () {
    // "Inviter" creates a submission & stores code
    cy.login(this.inviter).then(() => {
      subscribeToLecture(this.lecture.id);
      createEmptySubmission(this.lecture.id);
      cy.logout();
    });

    // "Joiner" joins the submission using the code
    cy.login(this.joiner).then(() => {
      subscribeToLecture(this.lecture.id);
      cy.visit(`/lectures/${this.tutorial.lecture_id}/submissions`);
      cy.getBySelector("submission-join").click();
      cy.getBySelector("submission-token-input").type(this.token);
      cy.getBySelector("submission-join-via-code").click();
      cy.getBySelector("submission-leave").should("be.visible");
      cy.logout();
    });

    // New assignment
    Timecop.moveAheadDays(1000).then(() => {
      FactoryBot.create("assignment", { lecture_id: this.lecture.id }).as("assignment");
      cy.reload();

      // "Inviter" reinvites "Joiner" to the submission
      cy.login(this.inviter).then(() => {
        createEmptySubmission(this.lecture.id);
        cy.logout();
      });

      // "Joiner" can now join without a code
      // (since this user has previously handed in a submission together
      // with the inviter, see above)
      cy.login(this.joiner).then(() => {
        cy.visit(`/lectures/${this.tutorial.lecture_id}/submissions`);
        cy.getBySelector("submission-join").click();
        cy.getBySelector("accept-invite").click();
        cy.getBySelector("submission-leave").should("be.visible");
      });
    });
  });
});
