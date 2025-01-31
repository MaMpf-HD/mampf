import FactoryBot from "../../support/factorybot";

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

function typeCyInInput(selector, waitForUserFill = true) {
  if (waitForUserFill) {
    cy.intercept("GET", "/users/fill_user_select*").as("userFill");
  }

  cy.getBySelector(selector).find("input:not([type='hidden'])")
    .should("have.length", 1).first().as("input");
  cy.getBySelector(selector).find("a.remove").click();
  cy.get("@input").click();

  // eslint-disable-next-line cypress/unsafe-to-chain-command
  cy.get("@input").type("cy", { timeout: 5000 }).should("have.value", "cy");

  if (waitForUserFill) {
    cy.wait("@userFill");
  }
}

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
      typeCyInInput("editor-select", false);
      shouldContainUsers("editor-select", this, false, false);
    });

    it("prohibits searching for arbitrary users in the tutor dropdown", function () {
      cy.visit(this.lecturePeopleUrl);
      cy.getBySelector("new-tutorial-btn").click();
      typeCyInInput("tutor-select-div", false);
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
      typeCyInInput("teacher-select");
      shouldContainUsers("teacher-select", this, true, true);
    });

    it("allows searching for arbitrary users to assign them as editors", function () {
      cy.visit(this.lecturePeopleUrl);
      typeCyInInput("editor-select");
      shouldContainUsers("editor-select", this, true, true);
    });

    it("allows to search for arbitrary users to assign them as tutors", function () {
      cy.visit(this.lecturePeopleUrl);
      cy.getBySelector("new-tutorial-btn").click();
      typeCyInInput("tutor-select-div");
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
  function openTalkForm() {
    cy.intercept("GET", "/talks/new*").as("newTalk");
    cy.getBySelector("new-talk-btn").click();
    cy.getBySelector("talk-form").should("be.visible");
    cy.wait("@newTalk");
    // I've tried many things to get it to work, but still had a failing test
    // here in the CI/CD pipeline. Cypress seems to not be able to type in
    // "cy" into the input field, see `typeCyInInput()`. It's probably because
    // the /talks/new request sends back JS with `fillOptionsByAjax` after
    // populating the modal. This might result in the input being reset after
    // cypress has already typed in "cy" (very quickly). So this is a workaround
    // to wait a bit before typing in the input field. In general, such waits
    // should only be used as a last resort.
    // eslint-disable-next-line cypress/no-unnecessary-waiting
    cy.wait(1000);
  }

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
      openTalkForm();
      shouldNotContainUserInOptions("speaker-select", this.user);
      typeCyInInput("speaker-select-div", false);
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
      openTalkForm();
      typeCyInInput("speaker-select-div");
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
      typeCyInInput("speaker-select-div", false);
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
      typeCyInInput("speaker-select-div");
      shouldContainUsers("speaker-select-div", this, true, true);
    });
  });
});
