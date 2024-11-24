import FactoryBot from "../support/factorybot";

const PROFILE_PAGE = "/profile/edit";

describe("Account settings", () => {
  beforeEach(function () {
    cy.createUserAndLogin("generic").as("user");
    cy.createUser("teacher").as("teacherUser");
    FactoryBot.create("lecture_with_sparse_toc").as("lecture");
    cy.then(() => {
      FactoryBot.create("valid_lesson", { lecture_id: this.lecture.id }).as("lesson");
    });
    cy.then(() => {
      FactoryBot.create("lesson_medium", "released",
        "with_lesson_by_id", { lesson_id: this.lesson.id }).as("medium");
    });
  });

  it("allows changing the user name & reflects this in user comments", function () {
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
