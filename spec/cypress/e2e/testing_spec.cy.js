describe("Testing", () => {

    beforeEach(() => {
        cy.app("clean");
    });
    describe("Set up test environment", () => {
        beforeEach(() => {
            cy.app("clean");
            cy.appScenario("admin");
            cy.visit("/users/sign_in");
            cy.get('input[type="email"]').type("administrator@mampf.edu");
            cy.get('input[type="password"]').type("test123456");
            cy.get('input[type="submit"]').click();
        });
		it("can view tutorials", () => {
            cy.appFactories([
            ]).then((lectures) => {
                
            });
        });
    });
});