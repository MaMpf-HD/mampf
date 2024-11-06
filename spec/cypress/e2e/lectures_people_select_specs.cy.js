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

function shouldContainUsers(selector, context, shouldContainUser, shouldContainTeacher) {
  const containUser = shouldContainUser ? "contain" : "not.contain";
  const containTeacher = shouldContainTeacher ? "contain" : "not.contain";

  cy.getBySelector(selector)
    .should(containUser, context.user.name_in_tutorials)
    .and(containUser, context.user.email)
    .and("not.contain", context.user.name);

  cy.getBySelector(selector)
    .should(containTeacher, context.teacher.name_in_tutorials)
    .and(containTeacher, context.teacher.email)
    .and("not.contain", context.teacher.name);
}

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
      shouldContainUsers("editor-select", this, false, false);
    });

    it("prohibits searching for arbitrary users in the tutor dropdown", function () {
      cy.visit(this.lecturePeopleUrl);
      cy.getBySelector("new-tutorial-btn").click();
      cy.getBySelector("tutor-select-div").click();
      cy.getBySelector("tutor-select-div").type("cy");
      shouldContainUsers("tutor-select-div", this, false, true);
    });
  });

  context("when logged in as admin", () => {
    beforeEach(function () {
      cy.logout();
      cy.createUserAndLogin("admin").as("admin");
    });

    it("allows searching for arbitrary users to assign them as teachers", function () {
      cy.visit(this.lecturePeopleUrl);
      cy.getBySelector("teacher-admin-select").type("cy");
      shouldContainUsers("teacher-admin-select", this, true, true);
    });

    it("allows searching for arbitrary users to assign them as editors", function () {
      cy.visit(this.lecturePeopleUrl);
      cy.getBySelector("editor-select").click();
      cy.getBySelector("editor-select").type("cy");
      shouldContainUsers("editor-select", this, true, true);
    });

    it("allows to search for arbitrary users to assign them as tutors", function () {
      cy.visit(this.lecturePeopleUrl);
      cy.getBySelector("new-tutorial-btn").click();
      cy.getBySelector("tutor-select-div").click();
      cy.getBySelector("tutor-select-div").type("cy");
      shouldContainUsers("tutor-select-div", this, true, true);
    });
  });
});

function shouldNotContainUserInOptions(selector, user) {
  cy.getBySelector(selector).within(() => {
    cy.get("option")
      .should("not.contain", user.name_in_tutorials)
      .and("not.contain", user.email)
      .and("not.contain", user.name);
  });
}

describe("Seminar speakers (new talk)", () => {
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
      shouldNotContainUserInOptions("speaker-select", this.user);
      cy.getBySelector("speaker-select-div").click();
      cy.getBySelector("speaker-select-div").type("cy");
      shouldContainUsers("speaker-select-div", this, false, true);
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
      shouldContainUsers("speaker-select-div", this, true, true);
    });
  });
});

describe("Seminar speakers (existing talk)", () => {
  beforeEach(function () {
    cy.createUser("generic").as("speaker");
    cy.createUser("generic").as("user");
    cy.createUserAndLogin("teacher").as("teacher");
    cy.then(() => {
      FactoryBot.create("seminar", { teacher_id: this.teacher.id }).as("seminar");
    });
    cy.then(() => {
      FactoryBot.create("talk",
        { lecture_id: this.seminar.id, speaker_ids: [this.speaker.id] }).as("talk");
    });
    cy.then(() => {
      cy.wrap(`/talks/${this.talk.id}/edit`).as("talkUrl");
    });
  });

  context("when logged in as teacher", () => {
    it("prohibits searching for arbitrary users in the speakers dropdown", function () {
      cy.visit(this.talkUrl);
      shouldNotContainUserInOptions("speaker-select", this.user);
      cy.getBySelector("speaker-select-div").find("input:not([type='hidden'])").type("cy");
      shouldContainUsers("speaker-select-div", this, false, true);
    });
  });

  context("when logged in as admin", () => {
    beforeEach(function () {
      cy.logout();
      cy.createUserAndLogin("admin").as("admin");
    });

    it("allows searching for arbitrary users to assign them as speakers", function () {
      cy.visit(this.talkUrl);
      cy.getBySelector("speaker-select-div").find("input:not([type='hidden'])").type("cy");
      shouldContainUsers("speaker-select-div", this, true, true);
    });
  });
});
