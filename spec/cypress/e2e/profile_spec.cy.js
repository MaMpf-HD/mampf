import FactoryBot from "../support/factorybot";

const PROFILE_PAGE = "/profile/edit";

describe("Module settings", () => {
  beforeEach(function () {
    cy.wrap("Happy course").as("courseName");
    cy.wrap("Happy division").as("divisionName");

    cy.then(() => {
      FactoryBot.create("division", { name: this.divisionName }).as("division");
    });

    cy.then(() => {
      FactoryBot.create("course", "with_division",
        { title: this.courseName, division_id: this.division.id }).as("course");
    });

    cy.then(() => {
      FactoryBot.create("lecture", "released_for_all",
        { course_id: this.course.id }).as("lecture");
    });
  });

  it("allows to subscribe to a lecture", function () {
    this.lecture.call.teacher().as("teacher");
    this.lecture.call.term().as("term");

    cy.createUserAndLogin("admin").as("admin");
    cy.visit(PROFILE_PAGE);

    cy.getBySelector("courses-accordion").find("button:visible").first().click();
    cy.getBySelector("courses-accordion").should("contain", this.divisionName);
    cy.contains(this.courseName).click();

    this.lecture.call.term_teacher_info().as("lectureName");
    cy.then(() => {
      cy.contains(this.lectureName).click();
      cy.contains(this.lectureName).parent().find("input").should("be.checked");
      cy.getBySelector("profile-change-submit").click();
    });

    cy.then(() => {
      cy.visit("/main/start");
      cy.getBySelector("subscribed-inactive-lectures-collapse").contains(this.courseName);
      cy.getBySelector("subscribed-inactive-lectures-collapse").contains(this.teacher.name);
    });
  });
});
