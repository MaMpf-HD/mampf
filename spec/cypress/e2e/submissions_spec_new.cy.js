import FactoryBot from "../support/factorybot";

describe("Submissions", () => {
  describe("User", () => {
    beforeEach(() => {
      cy.createUserAndLogin("generic");
      FactoryBot.create("lecture", "released_for_all");
    });

    it("can create a submission", function () {
      FactoryBot.create("tutorial", "with_tutors", { lecture_id: 1 }).as("tutorial");
      FactoryBot.create("assignment", { lecture_id: 1 }).as("assignment");
      cy.then(() => {
        console.log(this.tutorial);
        console.log(this.assignment);
        cy.visit("/lectures/1/");
      });
      // TODO: Implement the rest of the test
    });
  });
});
