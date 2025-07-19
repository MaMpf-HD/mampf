describe("Authentication", function () {
  beforeEach(() => {
    cy.app("clean");
  });
  describe("admin", () => {
    it("can login", () => {
      // call a scenario in app_commands/scenarios
      cy.appScenario("admin");
      cy.visit("/users/sign_in");
      cy.get('input[type="email"]').type("administrator@mampf.edu");
      cy.get('input[type="password"]').type("test123456");
      cy.get('input[type="submit"]').click();
      cy.url().should("contain", "main/start");
      cy.contains("Veranstaltungen").should("exist");
    });
    it("can set profile image", () => {
      cy.appScenario("admin");
      cy.visit("/users/sign_in");
      cy.get('input[type="email"]').type("administrator@mampf.edu");
      cy.get('input[type="password"]').type("test123456");
      cy.get('input[type="submit"]').click();
      cy.visit("/administration/profile");
      cy.contains("Profile Image").should("exist");
      const yourFixturePath = "cypress/fixtures/files/image.png";
      cy.get("#upload-image").selectFile(yourFixturePath, { force: true });
      cy.wait(100);
      cy.contains("Upload").click();
      cy.wait(100);
      cy.contains("Speichern").click();
      cy.contains("image.png").should("exist");
    });
  });
});
