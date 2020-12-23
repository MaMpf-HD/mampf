describe("Courses", function () {
    beforeEach(() => {
        cy.app("clean");
        cy.appScenario("setup");
    });
    describe("admin user", () => {
        beforeEach(() => {
            cy.appScenario("admin");
            cy.visit("/users/sign_in");
            cy.get('input[type="email"]').type("administrator@mampf.edu");
            cy.get('input[type="password"]').type("test123456");
            cy.get('input[type="submit"]').click();
        });
        it("can create module", () => {
             cy.visit('/administration');
             cy.get('i[title="Modul anlegen"]').click();
             cy.get('input[name="course[title]"]').type("Lineare Algebra I");
             cy.get('input[name="course[short_title]"]').type("LA I");
             cy.get('input[type="submit"]').click();
             cy.visit('/administration');
             cy.contains("Lineare Algebra I").should("exist");
         });
        it("can create lecture", () => {
            cy.appFactories([
                ['create', 'course'],
                ['create', 'term']
            ]).then((records) => {
                cy.server();
                cy.route('**/new').as('new');
                cy.route('POST', '/lectures').as('courses');
                cy.visit('/administration');
                cy.get('a[title="Veranstaltung anlegen"]').click();
                //cy.wait('@new');
                cy.get("div#new-lecture-area").contains("Speichern").click();
                cy.wait('@courses');
                cy.contains(records[0].title).should("exist");
                cy.contains(`${records[1].season} ${records[1].year}`).should("exist");
            });
        });

    });
    describe("simple user", () => {
        beforeEach(()=>{
            cy.appScenario("non_admin");
            cy.visit("/users/sign_in");
            cy.get('input[type="email"]').type("max@mampf.edu");
            cy.get('input[type="password"]').type("test123456");
            cy.get('input[type="submit"]').click();
        });
        it("can subscribe", () => {
            //call a scenario in app_commands/scenarios

            cy.appFactories([
                ['create_list', 'lecture', 6, 'released_for_all']
            ]).then((records) => {
                cy.visit("/main/start");
                cy.contains("Veranstaltungssuche").click();
                //cy.get('input[name="search[fulltext]"]').type(records[0][0].title)
                cy.contains("Suche").click();
                cy.get('[title="abonnieren"]').first().click();
                cy.get('[title="abbestellen"]').should("exist");
            });

        });
    });
});