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
    it("does not show element to select teacher", function () {
      cy.visit(this.lecturePeopleUrl);

      cy.getBySelector("teacher-admin-select").should("not.exist");
      cy.getBySelector("teacher-info").should("exist");
    });

    it("prohibits searching for arbitrary users in the editor dropdown", function () {
      cy.visit(this.lecturePeopleUrl);

      cy.getBySelector("editor-select").click();
      cy.getBySelector("editor-select").type("cy");

      cy.getBySelector("editor-select").should("not.contain", this.user.name_in_tutorials);
      cy.getBySelector("editor-select").should("not.contain", this.user.email);
    });
  });

  context("when logged in as admin", () => {
    beforeEach(function () {
      cy.logout();
      cy.createUserAndLogin("admin").as("admin");
    });

    function shouldContainAllUsers(selector, context) {
      cy.getBySelector(selector).should("contain", context.user.name_in_tutorials);
      cy.getBySelector(selector).should("contain", context.user.email);
      cy.getBySelector(selector).should("contain", context.teacher.name_in_tutorials);
      cy.getBySelector(selector).should("contain", context.teacher.email);
      cy.getBySelector(selector).should("contain", context.admin.name_in_tutorials);
      cy.getBySelector(selector).should("contain", context.admin.email);
    }

    it("allows searching for arbitrary users to assign them as teachers", function () {
      cy.visit(this.lecturePeopleUrl);

      cy.getBySelector("teacher-admin-select").should("be.visible");
      cy.getBySelector("teacher-admin-select").type("cy");
      shouldContainAllUsers("teacher-admin-select", this);
    });

    it.only("allows searching for arbitrary users to assign them as editors", function () {
      cy.visit(this.lecturePeopleUrl);

      cy.getBySelector("editor-select").click();
      cy.getBySelector("editor-select").type("cy");
      shouldContainAllUsers("editor-select", this);
    });
  });
});
