import FactoryBot from "../support/factorybot";

describe("Lecture edit page", () => {
  it("shows content tab button", function () {
    cy.createUserAndLogin("teacher").then((teacher) => {
      FactoryBot.create("lecture",
        { teacher_id: teacher.id }).as("lecture");
    });

    cy.then(() => {
      cy.visit(`/lectures/${this.lecture.id}/edit`);
      cy.getBySelector("content-tab-btn").should("be.visible");
    });
  });
});
