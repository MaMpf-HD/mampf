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

describe("Lecture people edit page", () => {
  beforeEach(function () {
    cy.createUser("generic").as("user");
    cy.createUserAndLogin("teacher").as("teacher");
    cy.then(() => {
      FactoryBot.create("lecture", { teacher_id: this.teacher.id }).as("lecture");
    });
    cy.then(() => {
      cy.wrap(`/lectures/${this.lecture.id}/edit#people`).as("lecturePeopleUrl");
    });
  });

  context("when logged in as teacher", () => {
    it.only("does not show element to select teacher", function () {
      cy.visit(this.lecturePeopleUrl);
      cy.getBySelector("teacher-admin-select").should("not.exist");
      cy.getBySelector("teacher-info").should("exist");
    });
  });

  context("when logged in as admin", () => {
    beforeEach(function () {
      cy.createUserAndLogin("admin").as("admin");
    });

    it("shows element to select teacher", function () {
      cy.logout();
      cy.createUserAndLogin("admin").as("admin");
      cy.visit(this.lecturePeopleUrl);

      cy.getBySelector("teacher-admin-select").should("be.visible");
      cy.getBySelector("teacher-admin-select").type("cy");

      cy.getBySelector("teacher-admin-select").should("contain", this.user.name_in_tutorials);
      cy.getBySelector("teacher-admin-select").should("contain", this.user.email);
      cy.getBySelector("teacher-admin-select").should("contain", this.teacher.name_in_tutorials);
      cy.getBySelector("teacher-admin-select").should("contain", this.teacher.email);
      cy.getBySelector("teacher-admin-select").should("contain", this.admin.name_in_tutorials);
      cy.getBySelector("teacher-admin-select").should("contain", this.admin.email);
    });
  });
});
