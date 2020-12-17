describe("Authentication", function () {
    beforeEach(() => {
        cy.app("clean");
    });
    describe("admin", () => {
        it("can login", () => {
            //call a scenario in app_commands/scenarios
            cy.appScenario("admin");
            cy.visit("/users/sign_in");
            cy.get('input[type="email"]').type("administrator@mampf.edu");
            cy.get('input[type="password"]').type("test123456");
            cy.get('input[type="submit"]').click();
            cy.url().should("contain", "main/start");
            cy.contains("Veranstaltungen").should("exist");
        });
    });
});