import FactoryBot from "../support/factorybot";

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

  function subscribeLecture(lectureId) {
    cy.visit(`/lectures/${lectureId}/subscribe`);
    cy.getBySelector("subscribe-to-lecture").click();
  }

  it.only("can join a submission by direct invite", function () {
    // "Inviter" creates a submission, copies code
    cy.login(this.inviter).then(() => {
      subscribeLecture(this.lecture.id);

      cy.visit(`/lectures/${this.tutorial.lecture_id}/submissions`);
      cy.getBySelector("create-submission").click();
      cy.getBySelector("save-submission").click();
      cy.getBySelector("submission-token").invoke("text").then((tokenRaw) => {
        const token = tokenRaw.trim();
        console.log("Submission token:", token);
        cy.wrap(token).as("token");
        cy.logout();
      });
    });

    // "Joiner" visits the submission page and joins using the copied code
    cy.login(this.joiner).then(() => {
      subscribeLecture(this.lecture.id);
      cy.visit(`/lectures/${this.tutorial.lecture_id}/submissions`);
      cy.getBySelector("submission-join").click();
      cy.getBySelector("submission-token-input").type(this.token);
      cy.getBySelector("submission-join-via-code").click();
      cy.getBySelector("submission-leave").should("be.visible");
    });
  });
});
