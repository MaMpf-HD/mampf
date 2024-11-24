import FactoryBot from "../support/factorybot";

const PROFILE_PAGE = "/profile/edit";

describe("Account settings", () => {
  beforeEach(function () {
    cy.createUserAndLogin("generic").as("user");
    cy.createUser("teacher").as("teacher");
    FactoryBot.create("lecture_with_sparse_toc", "released_for_all").as("lecture");
  });

  it("allows changing the user name & reflects it in user comments", function () {
    cy.then(() => {
      FactoryBot.create("valid_lesson", { lecture_id: this.lecture.id }).as("lesson");
    });
    cy.then(() => {
      FactoryBot.create("lesson_medium", "released",
        "with_lesson_by_id", { lesson_id: this.lesson.id }).as("medium");
    });

    cy.then(() => {
      cy.visit(PROFILE_PAGE);
      cy.getBySelector("display-name").should("have.value", this.user.name);

      cy.visit(`/media/${this.medium.id}/show_comments`);
      cy.getBySelector("new-comment").click();
      cy.getBySelector("comment-textarea").type("New comment");
      cy.getBySelector("submit-new-comment").click();
      cy.getBySelector("comment").should("contain", this.user.name);

      const newName = "Jean-Jacques Rousseau";
      cy.visit(PROFILE_PAGE);

      cy.getBySelector("display-name").clear();
      cy.getBySelector("display-name").type(newName);
      cy.getBySelector("profile-change-submit").click();

      cy.visit(`/media/${this.medium.id}/show_comments`);
      cy.getBySelector("comment").should("contain", newName);
    });
  });

  it.only("allows changing the user name in tutorials & reflects it in submissions", function () {
    cy.createUser("tutor").as("tutor");

    const newName = "Voltaire";

    cy.then(() => {
      cy.visit(PROFILE_PAGE);
      cy.getBySelector("display-name-tutorials").should("have.value", this.user.name_in_tutorials);

      cy.getBySelector("display-name-tutorials").clear();
      cy.getBySelector("display-name-tutorials").type(newName);
      cy.getBySelector("profile-change-submit").click();
    });

    cy.then(() => {
      FactoryBot.create("tutorial", "with_tutor_by_id",
        { lecture_id: this.lecture.id, tutor_id: this.tutor.id }).as("tutorial");
      FactoryBot.create("assignment", { lecture_id: this.lecture.id }).as("assignment");
    });

    cy.then(() => {
      cy.visit(`/lectures/${this.lecture.id}`);

      cy.intercept("PATCH", "profile/subscribe_lecture*").as("subscribeToLecture");
      cy.getBySelector("subscribe-to-lecture").click();
      cy.wait("@subscribeToLecture");

      cy.visit(`/lectures/${this.lecture.id}/submissions`);

      // Upload new submission
      cy.getBySelector("create-submission").click();
      cy.getBySelector("choose-user-submission").click();
      cy.getBySelector("choose-user-submission-file")
        .selectFile("cypress/fixtures/files/manuscript.pdf", { force: true });
      cy.getBySelector("file-permission-accept").click();
      cy.getBySelector("upload-user-submission").click();
      cy.getBySelector("save-submission").click();
    });

    cy.then(() => {
      cy.logout();
      cy.login(this.tutor);
      cy.visit(`/lectures/${this.lecture.id}/tutorials`);

      cy.getBySelector("tutorial-submissions-table")
        .should("contain", newName);
      cy.getBySelector("tutorial-submissions-table")
        .should("not.contain", this.user.name_in_tutorials);
      cy.getBySelector("tutorial-submissions-table")
        .should("not.contain", this.user.name);
    });
  });
});
