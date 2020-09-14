describe("Courses", function () {
    beforeEach(() => {
        cy.app("clean");
        cy.appScenario("admin");
        cy.appScenario("setup");
    });
    describe("admin user",()=>{
        it("can create module",()=>{
            cy.visit("/users/sign_in");
            cy.get('input[type="email"]').type("administrator@mampf.edu");
            cy.get('input[type="password"]').type("test123456");
            cy.get('input[type="submit"]').click();
            cy.visit('/administration');
            cy.get('i[title="Modul anlegen"]').click();
            cy.get('input[name="course[title]"]').type("Lineare Algebra I");
            cy.get('input[name="course[short_title]"]').type("LA I");
            cy.get('input[type="submit"]').click();
            cy.contains("Lineare Algebra I").should("exist");
        });
    });
    describe("simple user", () => {
        it("can subscribe", () => {
            //call a scenario in app_commands/scenarios
            cy.appScenario("non_admin");
            cy.appScenario("course_created");
            cy.visit("/users/sign_in");
            cy.appFactories([
                ['create_list', 'lecture', 10]]).then((records)=>{
                    console.log(records);
                });
            cy.get('input[type="email"]').type("max@mampf.edu");
            cy.get('input[type="password"]').type("test123456");
        });
    });
});