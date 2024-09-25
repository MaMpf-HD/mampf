import FactoryBot from "../../support/factorybot";

describe("FactoryBot.create()", () => {
  beforeEach(function () {
    cy.createUserAndLogin("teacher").as("teacher");
  });

  it("allows to call create() with array as argument", function () {
    cy.createUser("generic").as("tutor1");
    cy.createUser("generic").as("tutor2");
    FactoryBot.create("lecture", { teacher_id: this.teacher.id }).as("lecture");

    cy.then(() => {
      // here we pass in an array as argument to tutor_ids
      FactoryBot.create("tutorial",
        { lecture_id: this.lecture.id, tutor_ids: [this.tutor1.id, this.tutor2.id] },
      );
    });
  });
});

describe("FactoryBot.create().call", () => {
  beforeEach(function () {
    cy.createUser("teacher").as("teacher");
    cy.createUserAndLogin("generic");
  });

  it("allows to call instance methods after assigning them to an alias", function () {
    FactoryBot.create("lecture", { teacher_id: this.teacher.id }).as("lecture");

    cy.then(() => {
      // via alias in global this namespace
      this.lecture.call.long_title().then((res) => {
        cy.log(res);
      });
    });
  });

  it("allows to call instance methods directly (without an alias)", function () {
    FactoryBot.create("lecture", { teacher_id: this.teacher.id }).then((lecture) => {
      // via return value of FactoryBot.create() directly (no alias intermediate)
      lecture.call.long_title().then((res) => {
        cy.log(res);
      });
    });
  });
});
