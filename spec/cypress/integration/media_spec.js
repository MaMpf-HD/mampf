describe("Media", () => {

    beforeEach(() => {
        cy.app("clean");
    });
    describe("Simple User",()=>{
        beforeEach(() => {
            cy.app("clean");
            cy.appScenario("non_admin");
            cy.visit("/users/sign_in");
            cy.get('input[type="email"]').type("max@mampf.edu");
            cy.get('input[type="password"]').type("test123456");
            cy.get('input[type="submit"]').click();
        });
        it("can view media",()=>{
            cy.appFactories([
                
                [
                "create","lesson_medium", "with_manuscript","released"
            ],
            ["create", "lecture_user_join", {
                user_id: 1,
                lecture_id: 1
            }]]).then((records)=>{
                console.log(records);
                cy.visit(`/media/${records[0].id}`);
                cy.contains(records[0].description).should("exist");
            });
        });
        it("can comment media",()=>{
            cy.appFactories([
                
                [
                "create","lesson_medium", "with_manuscript","released"
            ],
            ["create", "lecture_user_join", {
                user_id: 1,
                lecture_id: 1
            }]]).then((records)=>{
                console.log(records);
                cy.visit(`/media/${records[0].id}`);
                cy.contains(records[0].description).should("exist");
                cy.contains("Neuer Kommentar").click();
                cy.get('textarea[name="comment[body]"]').type("Dies ist ein super Test Kommentar");
                cy.contains("Kommentar speichern").click();
                cy.contains("Test Kommentar").should("exist");
            });
        })
    })
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
                cy.wait(100);
                cy.get('input[name="medium[release_date]"]').click().clear().type(date.toLocaleString("de").replace(",",""));
                cy.wait(100);
                cy.contains("Ich bestätige hiermit, dass durch die Veröffentlichung des Mediums auf der MaMpf-Plattform keine Rechte Dritter verletzt werden.").click();
                cy.get("#publishMediumModal").contains("Speichern").click();
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
                cy.get("#publishMediumModal").contains("Speichern").click();
                cy.visit(`lectures/${lectures[0].id}/food?project=kaviar`);
                cy.contains("Media 1").should("exist");
            });
        });
        it("can create medium & release it scheduled with submission", () => {
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
                cy.get('select[name="medium[sort]"]').select("Übung");
                cy.contains("Speichern und bearbeiten").click();
                cy.contains("Media 1").should("exist");
                cy.contains("Veröffentlichen").click();
                cy.wait(100);
                cy.contains("zum folgenden Zeitpunkt").click();
                cy.contains("Hausaufgabe zu diesem Medium anlegen").click();

                var date = new Date();
                date.setDate(date.getDate() + 7);
                console.log(date);
                cy.get('input[name="medium[release_date]"]').click().clear().type(date.toLocaleString("de"));
                date.setDate(date.getDate() + 8);
                cy.get('input[name="medium[assignment_deadline]"]').click().clear().type(date.toLocaleString("de"));
                cy.contains("Ich bestätige hiermit, dass durch die Veröffentlichung des Mediums auf der MaMpf-Plattform keine Rechte Dritter verletzt werden.").click();
                cy.get("#publishMediumModal").contains("Speichern").click();
                cy.contains("Dieses Medium wird planmäßig").should("exist");
            });
        });
    });
});