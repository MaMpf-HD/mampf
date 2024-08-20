import FactoryBot from "../support/factorybot";

const ROLES = ["tutor", "editor", "teacher", "speaker"];

function createLectureScenario(context, type = "lecture") {
  cy.createUserAndLogin("teacher").as("teacher");

  cy.then(() => {
    FactoryBot.create(type, "with_teacher_by_id", { teacher_id: context.teacher.id }).as("lecture");
  });

  cy.then(() => {
    cy.visit(`/lectures/${context.lecture.id}/edit`);
    cy.getBySelector("people-tab-btn").click();
  });

  cy.i18n("basics.vouchers").as("vouchers");
}

describe("If the lecture is not a seminar", () => {
  beforeEach(function () {
    createLectureScenario(this);
  });

  describe("People tab in lecture edit page", () => {
    it("shows buttons for creating tutor, editor and teacher vouchers", function () {
      cy.then(() => {
        cy.contains(this.vouchers).should("be.visible");
        ROLES.filter(role => role !== "speaker").forEach((role) => {
          cy.getBySelector(`create-${role}-voucher-btn`).should("be.visible");
        });
      });
    });
  });
});

describe("If the lecture is a seminar", () => {
  beforeEach(function () {
    createLectureScenario(this, "seminar");
  });

  describe("People tab in lecture edit page", () => {
    it("shows buttons for creating tutor, editor, teacher, and speaker vouchers", function () {
      cy.then(() => {
        cy.contains(this.vouchers).should("be.visible");
        ROLES.forEach((role) => {
          cy.getBySelector(`create-${role}-voucher-btn`).should("be.visible");
        });
      });
    });
  });
});
