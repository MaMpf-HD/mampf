import FactoryBot from "../../support/factorybot";

describe("FactoryBot.create()", () => {
  beforeEach(function () {
    cy.createUser("teacher").as("teacher");
    cy.createUserAndLogin("generic");
  });

  it("allows to call instance method after assigning them to an alias", function () {
    FactoryBot.create("lecture", { teacher_id: this.teacher.id }).as("lecture");

    cy.then(() => {
      // via alias in global this namespace
      this.lecture.call.rails_number_test(42, 43).then((res) => {
        cy.log(res);
      });
    });
  });

  it("allows to call instance methods directly (without alias)", function () {
    FactoryBot.create("lecture", { teacher_id: this.teacher.id }).then((lecture) => {
      // via return value of FactoryBot.create() directly (no alias intermediate)
      lecture.call.rails_number_test(42, 43).then((res) => {
        cy.log(res);
      });
    });
  });
});
