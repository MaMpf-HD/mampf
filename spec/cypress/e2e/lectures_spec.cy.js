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

describe("Lecture people edit page: teacher & editor", () => {
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

    it("prohibits searching for arbitrary users in the tutor dropdown", function () {
      cy.visit(this.lecturePeopleUrl);
      cy.getBySelector("new-tutorial-btn").click();
      cy.getBySelector("tutor-select-div").click();
      cy.getBySelector("tutor-select-div").type("cy");

      cy.getBySelector("tutor-select-div").should("not.contain", this.user.name_in_tutorials);
      cy.getBySelector("tutor-select-div").should("not.contain", this.user.email);
      cy.getBySelector("tutor-select-div").should("contain", this.teacher.name_in_tutorials);
      cy.getBySelector("tutor-select-div").should("contain", this.teacher.email);
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

    it("allows searching for arbitrary users to assign them as editors", function () {
      cy.visit(this.lecturePeopleUrl);
      cy.getBySelector("editor-select").click();
      cy.getBySelector("editor-select").type("cy");
      shouldContainAllUsers("editor-select", this);
    });

    it("allows to search for arbitrary users to assign them as tutors", function () {
      cy.visit(this.lecturePeopleUrl);
      cy.getBySelector("new-tutorial-btn").click();
      cy.getBySelector("tutor-select-div").click();
      cy.getBySelector("tutor-select-div").type("cy");
      shouldContainAllUsers("tutor-select-div", this);
    });
  });
});

describe("Seminar speakers", () => {
  beforeEach(function () {
    cy.createUser("generic").as("user");
    cy.createUserAndLogin("teacher").as("teacher");
    cy.then(() => {
      FactoryBot.create("seminar", { teacher_id: this.teacher.id }).as("seminar");
    });
    cy.then(() => {
      cy.wrap(`/lectures/${this.seminar.id}/edit`).as("seminarUrl");
    });
  });

  context("when logged in as teacher", () => {
    it("prohibits searching for arbitrary users in the speakers dropdown", function () {
      cy.visit(this.seminarUrl);
      cy.getBySelector("new-talk-btn").click();
      cy.getBySelector("talk-form").should("be.visible");
      cy.getBySelector("speaker-select").within(() => {
        cy.get("option")
          .should("not.contain", this.user.name_in_tutorials)
          .and("not.contain", this.user.email)
          .and("not.contain", this.user.name);
      });

      // type "cy" to trigger search
      cy.getBySelector("speaker-select-div").click();
      cy.getBySelector("speaker-select-div").type("cy");

      cy.getBySelector("speaker-select-div")
        .should("not.contain", this.user.name_in_tutorials)
        .and("not.contain", this.user.email)
        .and("not.contain", this.user.name);
      cy.getBySelector("speaker-select-div")
        .should("contain", this.teacher.name_in_tutorials)
        .and("contain", this.teacher.email)
        .and("not.contain", this.teacher.name);
    });
  });

  context("when logged in as admin", () => {
    beforeEach(function () {
      cy.logout();
      cy.createUserAndLogin("admin").as("admin");
    });

    it("allows searching for arbitrary users to assign them as speakers", function () {
      cy.visit(this.seminarUrl);
      cy.getBySelector("new-talk-btn").click();
      cy.getBySelector("talk-form").should("be.visible");

      cy.getBySelector("speaker-select-div").click();
      cy.getBySelector("speaker-select-div").type("cy");

      cy.getBySelector("speaker-select-div")
        .should("contain", this.user.name_in_tutorials)
        .and("contain", this.user.email)
        .and("not.contain", this.user.name);
      cy.getBySelector("speaker-select-div")
        .should("contain", this.teacher.name_in_tutorials)
        .and("contain", this.teacher.email)
        .and("not.contain", this.teacher.name);
    });
  });
});
