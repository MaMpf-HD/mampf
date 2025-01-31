import FactoryBot from "../../support/factorybot";

describe("New lecture (via admin index page)", () => {
  beforeEach(function () {
    cy.createUserAndLogin("admin").as("admin");

    FactoryBot.create("course").as("course");
    cy.then(() => {
      FactoryBot.create("term").as("term");
    });
  });

  it.only("Creates new lecture", function () {
    cy.visit("/administration");
    cy.getBySelector("new-lecture-button-admin-index").click();

    cy.getBySelector("new-lecture-course-select-div").then(($wrapperDiv) => {
      cy.wrap($wrapperDiv).selectTom(this.course.title);
    });
    cy.getBySelector("new-lecture-submit").click();

    const successMessage = this.admin.locale === "de" ? "erfolgreich" : "successfully";
    cy.get("div.alert")
      .should("contain", this.course.title)
      .should("contain", this.term.season)
      .should("contain", this.admin.name)
      .should("contain", successMessage);
  });
});
