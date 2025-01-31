import FactoryBot from "../../support/factorybot";

describe("New lecture (via admin index page)", () => {
  beforeEach(function () {
    cy.createUserAndLogin("admin").as("admin");
    FactoryBot.create("course", "with_division", { title: "Curves" }).as("course");
    cy.then(() => {
      FactoryBot.create("term").as("term");
    });
  });

  it.only("Creates new lecture", function () {
    cy.visit("/administration");
    cy.getBySelector("new-lecture-button-admin-index").click();

    cy.getBySelector("new-lecture-course-select-div").as("wrapperDiv");

    cy.then(() => {
      cy.get("@wrapperDiv").find(".ts-control").find("input").click();
      const name = "Curves";
      cy.get("@wrapperDiv").find("select").find("option").contains(name).should("exist");
      cy.get("div.ts-dropdown").contains(name).as("dropdownItem");
      cy.then(() => {
        cy.get("@dropdownItem").should("have.attr", "data-selectable");
        cy.get("@dropdownItem").click();
      });
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
