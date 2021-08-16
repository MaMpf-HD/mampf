import { recurse } from 'cypress-recurse'

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
            cy.contains("Speichern").click();
            cy.contains("image.png").should("exist");
        });
    });
    describe("Simple user", () => {
        it("can sign up", () => {
            // by now the SMTP server has probably received the email
            cy.visit('/users/sign_up');
            cy.get('input[type="email"]').type("joe@mampf.edu");
            cy.get("input[name='user[password]']").type("sup3r_s3cr3t");
            cy.get("input[name='user[password_confirmation]']").type("sup3r_s3cr3t");
            cy.get("#dsgvo-consent").check();
            cy.wait(100);
            cy.get("form").contains("Registrieren").click();
            cy.wait(3000);
            recurse(() => cy.task('getLastEmail', 'joe@mampf.edu'), Cypress._.isObject, {
                log: false,
                delay: 1000,
                timeout: 20000,
            })
                .its('html') // check the HTML email text
                // what do we do now?
                .then((html) => {
                    cy.document().invoke('write', html)
                    cy.contains("Account bestätigen").click();
                    cy.contains("Account").should("exist");
                })
        })
    });
});

