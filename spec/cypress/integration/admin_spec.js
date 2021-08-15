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
        it("can set profile image", () => {
            cy.appScenario("admin");
            cy.visit("/users/sign_in");
            cy.get('input[type="email"]').type("administrator@mampf.edu");
            cy.get('input[type="password"]').type("test123456");
            cy.get('input[type="submit"]').click();
            cy.visit(`/administration/profile`);
            cy.contains("Profile Image").should("exist");
            const yourFixturePath = 'files/image.png';
            cy.get('input[name="files[]"]').attachFile(yourFixturePath);
            cy.wait(100);
            cy.wait("Upload").click();
            cy.wait(100);
            cy.contains("Speichern").click();
            cy.contains("image.png").should("exist");
        });
    });
});

describe("Clicker Admin", function () {
    beforeEach(() => {
        cy.app("clean");
        cy.appScenario("admin");
        cy.visit("/users/sign_in");
        cy.get('input[type="email"]').type("administrator@mampf.edu");
        cy.get('input[type="password"]').type("test123456");
        cy.get('input[type="submit"]').click();
    });

    it("can create clicker", () => {
        cy.visit("/administration");
        cy.get('a[title="Clicker anlegen"]').click();
        cy.get('input[name="clicker[title]"]').type("ErsterClicker");
        cy.get("div#new-clicker-area").contains("Speichern").click();
        cy.contains("ErsterClicker").should("exist");
    });

    it("can show clicker qr", () => {
        cy.appFactories([
            ['create', 'clicker', 'with_editor']
        ]).then((clickers) => {
            cy.visit(`/clickers/${clickers[0].id}/edit`);
            cy.contains("QR-Code zeigen").click();
            cy.get("li#clickerQRCode").should("exist");
        });

    });
});