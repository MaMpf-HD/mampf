import FactoryBot from "../../support/factorybot";

describe("New lecture", () => {
  beforeEach(function () {
    cy.createUserAndLogin("admin").as("admin");

    FactoryBot.create("course").as("course");
    cy.then(() => {
      FactoryBot.create("term").as("term");
    });
  });

  it("Creates new lecture (via index page", function () {
    cy.visit("/administration");
    testCreateNewLecture(this, false);
  });

  it("Creates new lecture (via course edit page)", function () {
    cy.visit(`/courses/${this.course.id}/edit`);
    testCreateNewLecture(this, true);
  });
});

function testCreateNewLecture(context, isCoursePrefilled) {
  cy.getBySelector("new-lecture-button-admin-index").click();

  if (!isCoursePrefilled) {
    cy.getBySelector("new-lecture-course-select-div").then(($wrapperDiv) => {
      cy.wrap($wrapperDiv).selectTom(context.course.title);
    });
  }

  cy.getBySelector("new-lecture-submit").click();

  const successMessage = context.admin.locale === "de" ? "erfolgreich" : "successfully";
  cy.get("div.alert")
    .should("contain", context.course.title)
    .should("contain", context.term.season)
    .should("contain", context.admin.name)
    .should("contain", successMessage);
}
