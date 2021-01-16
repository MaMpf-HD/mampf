describe("Submissions", () => {

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
        it("can create tutorial", () => {
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
                cy.get('input[role="searchbox"]').type(lectures[1].name);
                cy.contains(lectures[1].name).click();
                cy.get("#exercises_collapse").contains("Speichern").click();
            });
        })
        it("can create assignment", () => {
            cy.appFactories([
                ["create",
                    "lecture", {
                        "teacher_id": 1
                    }
                ],
                [
                    "create", "tutorial", {
                        "lecture_id": 1
                    }
                ]
            ]).then((tutorials) => {
                console.log(tutorials[1]);
                cy.visit(`/lectures/${tutorials[1].lecture_id}/edit`);
                cy.contains("Hausaufgaben").should("exist");
                cy.contains("Hausaufgaben").click();
                cy.contains("Neue Hausaufgabe anlegen").click();
                cy.get('input[name="assignment[title]"]').type("Assignment A");
                cy.get('input[name="assignment[deadline]"]').type((new Date()).toLocaleTimeString("de"));
                cy.get("#assignments_collapse").contains("Speichern").click();
                cy.contains("Assignment A").should("exist");
            });
        });
    });
    describe("User", () => {
        beforeEach(() => {
            cy.app("clean");
            cy.appScenario("non_admin");
            cy.visit("/users/sign_in");
            cy.get('input[type="email"]').type("max@mampf.edu");
            cy.get('input[type="password"]').type("test123456");
            cy.get('input[type="submit"]').click();

            cy.appFactories([
                ["create", "lecture", "released_for_all"],
                ["create", "lecture_user_join", {
                    user_id: 1,
                    lecture_id: 1
                }]
            ]).then((lectures) => {});
        });
        it("can create submission", () => {
            cy.appFactories([
                [
                    "create",
                    "tutorial", "with_tutors", {
                        lecture_id: 1
                    }
                ],
                [
                    "create", "assignment", {
                        lecture_id: 1
                    }
                ]
            ]).then((assignments) => {
                cy.visit(`lectures/${assignments[0].lecture_id}/submissions`);
                cy.contains("Anlegen").click();
                const yourFixturePath = 'files/manuscript.pdf';
                cy.get('#upload-userManuscript').attachFile(yourFixturePath);
                cy.get('input[type="checkbox"]').check();
                cy.contains("Hochladen").click();
                cy.get(".submissionFooter").contains("Speichern").click();
                cy.contains("Du").should("exist");
            });
        });
        it("can join submission", () => {
            cy.appFactories([
                [
                    "create",
                    "tutorial", "with_tutors", {
                        lecture_id: 1
                    }
                ],
                [
                    "create", "assignment", {
                        lecture_id: 1
                    }
                ],
                ["create", "submission", "with_users", "with_manuscript", {
                    assignment_id: 1,
                    tutorial_id: 1
                }]
            ]).then((assignments) => {
                cy.visit(`lectures/${assignments[0].lecture_id}/submissions`);
                cy.contains("Beitreten").click();
                cy.contains("Code").should("exist");
                console.log(assignments[2]);
                cy.get('input[name="join[code]"]').type(assignments[2].token);
                cy.contains("Beitreten").click();
                cy.contains("Du").should("exist");
            });
        });
    });

});