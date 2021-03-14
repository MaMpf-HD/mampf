describe("Media", () => {

    beforeEach(() => {
        cy.app("clean");
    });
    describe("Administration", () => {
        beforeEach(() => {
            cy.app("clean");
            cy.appScenario("admin");
            cy.visit("/users/sign_in");
            cy.get('input[type="email"]').type("administrator@mampf.edu");
            cy.get('input[type="password"]').type("test123456");
            cy.get('input[type="submit"]').click();
        });
        it("can create medium & release it scheduled", () => {
            cy.appFactories([
                ["create",
                    "lecture", {
                        "teacher_id": 1,
                        "released": "all"
                    }
                ]
            ]).then((lectures) => {
                cy.visit(`lectures/${lectures[0].id}/edit`);
                cy.contains("Medium anlegen").should("exist");
                cy.contains("Medium anlegen").click();
                cy.get('input[name="medium[description]"]').type("Media 1");
                cy.contains("Speichern und bearbeiten").click();
                cy.contains("Media 1").should("exist");
                cy.contains("Veröffentlichen").click();
                cy.wait(100);
                cy.contains("zum folgenden Zeitpunkt").click();
                var date = new Date();
                date.setDate(date.getDate() + 7);
                console.log(date);
                cy.get('input[name="medium[release_date]"]').click().clear().type(date.toLocaleString("de"));
                cy.contains("Ich bestätige hiermit, dass durch die Veröffentlichung des Mediums auf der MaMpf-Plattform keine Rechte Dritter verletzt werden.").click();
                cy.get("#publishMediumModal").contains("Veröffentlichen").click();
                cy.contains("Dieses Medium wird planmäßig").should("exist");
            });
        });
        it("can create medium & release it.", () => {
            cy.appFactories([
                ["create",
                    "lecture", {
                        "teacher_id": 1,
                        "released": "all"
                    }
                ],
                ["create",
                    "lecture_user_join", {
                        "user_id": 1,
                        "lecture_id": 1
                    }
                ]
            ]).then((lectures) => {
                cy.visit(`lectures/${lectures[0].id}/edit`);
                cy.contains("Medium anlegen").should("exist");
                cy.contains("Medium anlegen").click();
                cy.get('input[name="medium[description]"]').type("Media 1");
                cy.contains("Speichern und bearbeiten").click();
                cy.contains("Media 1").should("exist");
                cy.contains("Veröffentlichen").click();
                cy.contains("Ich bestätige hiermit, dass durch die Veröffentlichung des Mediums auf der MaMpf-Plattform keine Rechte Dritter verletzt werden.").click();
                cy.get("#publishMediumModal").contains("Veröffentlichen").click();
                cy.visit(`lectures/${lectures[0].id}/food?project=kaviar`);
                cy.contains("Media 1").should("exist");
            });
        });
    });
});