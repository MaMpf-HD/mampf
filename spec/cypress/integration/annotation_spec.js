describe("Annotations", () => {

    beforeEach(() => {
        cy.app("clean");
    });
    describe("AnnotationForAdmin", () => {
        beforeEach(() => {
            cy.app("clean");
            cy.appScenario("admin");
            cy.visit("/users/sign_in");
            cy.get('input[type="email"]').type("administrator@mampf.edu");
            cy.get('input[type="password"]').type("test123456");
            cy.get('input[type="submit"]').click();
            
            cy.appFactories([
                ["create",
                    "lecture", {
                        "teacher_id": 1
                    }
                ],
                ["create", "user", "auto_confirmed"]
            ]).then((lectures) => {
                cy.visit(`lectures/${lectures[0].id}/edit`);
                cy.contains("Tutorien").should("exist");
                cy.contains("Tutorien").click();
                cy.contains("Neues Tutorium anlegen").click();
                cy.get('input[name="tutorial[title]"]').type("Tutorium A");
                cy.get('#tutorial_tutor_ids_-ts-control').type(lectures[1].name);
                cy.contains(lectures[1].name).click();
                cy.get("#exercises_collapse").contains("Speichern").click();
            });
        });
        
        it("can create annotation", () => {
            // TODO
        })
	});
});
