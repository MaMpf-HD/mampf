import FactoryBot from "../support/factorybot";

describe("Submissions", () => {
  describe("User", () => {
    beforeEach(() => {
      cy.createUserAndLogin("generic");
      FactoryBot.create("lecture", "released_for_all");
    });

    // TODO: this is just a dummy test right now
    it("can create a submission", function () {
      FactoryBot.create("tutorial", "with_tutors", { lecture_id: 1 }).as("tutorial");
      FactoryBot.create("assignment", { lecture_id: 1 }).as("assignment");
      cy.createUser("admin").as("user");

      cy.then(() => {
        console.log(this.tutorial);
        console.log(this.assignment);
        console.log(this.user);
      });

      cy.then(() => {
        cy.visit("/lectures/1/");
      });
    });
  });
});
