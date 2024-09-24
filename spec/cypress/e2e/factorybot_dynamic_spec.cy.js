import FactoryBot from "../support/factorybot";

describe("FactoryBot dynamic", () => {
  beforeEach(function () {
    cy.createUser("teacher").as("teacher");
    cy.createUserAndLogin("generic").as("user");
    cy.then(() => {
      FactoryBot.create("lecture", { teacher_id: this.teacher.id }).as("lecture");
    });
  });

  it("Instance methods", function () {
    console.log(this.lecture);
    this.lecture.call.qed();
  });
});
