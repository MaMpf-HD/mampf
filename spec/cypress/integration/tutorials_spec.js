describe("Tutorials", () => {

    beforeEach(() => {
        cy.app("clean");
    });
    describe("Teacher", () => {
        beforeEach(() => {
            cy.app("clean");
            cy.appScenario("teacher");
            cy.visit("/users/sign_in");
            cy.get('input[type="email"]').type("teacher@mampf.edu");
            cy.get('input[type="password"]').type("test123456");
            cy.get('input[type="submit"]').click();
        });
		it("can view tutorials", () => {
            cy.appFactories([
                ["create",
                    "lecture", {
                        teacher_id: 1
                    }
                ],
                ["create",
                    "lecture_user_join", {
                        user_id: 1,
                        lecture_id: 1
                    }
                ],
                ["create",
                    "tutorial", "with_tutors", {
                        lecture_id: 1
                    }
                ],
                ["create",
                    "assignment", {
                        lecture_id: 1
                    }
                ],
                ["create", "submission", "with_users", "with_manuscript", "with_correction", {
                    assignment_id: 1,
                    tutorial_id: 1
                }]
            ]).then((lectures) => {
                cy.visit(`lectures/${lectures[0].id}`);
                cy.contains("Tutorien").should("exist");
                cy.contains("Tutorien").click();
                cy.get('.col-sm-9 > .dropdown > .btn').contains("Tutorien").should("exist");
                cy.get('.col-sm-9 > .dropdown > .btn').contains("Tutorien").click();
                cy.get('.col-sm-9 > .dropdown > .dropdown-menu > .dropdown-item').contains(lectures[2].title).click();
                cy.contains("Übersicht").should("exist");
            });
        });
        it("can view tutorials if tutor", () => {
            cy.appFactories([
                ["create",
                    "lecture", {
                        teacher_id: 1
                    }
                ],
                ["create",
                    "lecture_user_join", {
                        user_id: 1,
                        lecture_id: 1
                    }
                ],
                ["create",
                    "tutorial", {
                        lecture_id: 1,
                        tutor_ids: [1]
                    }
                ],
                ["create",
                    "tutorial", "with_tutors", {
                        lecture_id: 1
                    }
                ],
                ["create",
                    "assignment", {
                        lecture_id: 1
                    }
                ],
                ["create", "submission", "with_users", "with_manuscript", "with_correction", {
                    assignment_id: 1,
                    tutorial_id: 1
                }]
            ]).then((lectures) => {
                cy.visit(`lectures/${lectures[0].id}`);
                cy.contains("Tutorien").should("exist");
                cy.contains("Tutorien").click();
                cy.contains("Übersicht").should("exist");
                cy.contains("Übersicht").click();
                cy.get('.col-sm-9 > .dropdown > .btn').contains("Tutorien").click();
                cy.contains('Eigene Tutorien').should('exist');
                cy.contains('Sonstige Tutorien').should('exist');
                cy.get('.dropdown-menu').contains(lectures[2].title).should("exist");
                cy.get('.dropdown-menu').contains(lectures[3].title).should("exist");
            });
        });
        it("can create correction if tutor", () => {
            cy.appFactories([
                ["create",
                    "lecture", {
                        teacher_id: 1
                    }
                ],
                ["create",
                    "lecture_user_join", {
                        user_id: 1,
                        lecture_id: 1
                    }
                ],
                ["create",
                    "tutorial", {
                        lecture_id: 1,
                        tutor_ids: [1]
                    }
                ],
                ["create",
                    "assignment", "inactive", {
                        lecture_id: 1
                    }
                ],
                ["create",
                    "assignment", {
                        lecture_id: 1
                    }
                ],
                ["create", "submission", "with_users", "with_manuscript", {
                    assignment_id: 1,
                    tutorial_id: 1
                }],
                ["create", "submission", "with_users", "with_manuscript", {
                    assignment_id: 2,
                    tutorial_id: 1
                }]
            ]).then((lectures) => {
                cy.visit(`lectures/${lectures[0].id}`);
                cy.contains("Tutorien").click();
                cy.contains("Achtung").should("exist");
                cy.contains(lectures[4].title).click();
                cy.contains(lectures[3].title).click();
                cy.contains("Akzeptieren").click();
                cy.reload();
                cy.get(".correction-column").contains("Hochladen").click();
                const yourFixturePath = 'files/manuscript.pdf';
                cy.get(".correction-column").contains("Datei").click();
                cy.get(`#upload-correction-${lectures[5].id}`).attachFile(yourFixturePath);
                cy.contains("Upload").click();
                cy.get('.correction-upload > .mt-2 > .col-12 > .btn-primary').contains("Speichern").click();
                cy.reload();
                cy.get('.correction-action-area > [data-turbolinks="false"]').should("exist");
            });
        });
        it("can move submission if tutor", () => {
            cy.appFactories([
                ["create",
                    "lecture", {
                        teacher_id: 1
                    }
                ],
                ["create",
                    "lecture_user_join", {
                        user_id: 1,
                        lecture_id: 1
                    }
                ],
                ["create",
                    "tutorial", {
                        lecture_id: 1,
                        tutor_ids: [1]
                    }
                ],
                ["create",
                    "tutorial", {
                        lecture_id: 1
                    }
                ],
                ["create",
                    "assignment", {
                        lecture_id: 1
                    }
                ],
                ["create", "submission", "with_users", "with_manuscript", {
                    assignment_id: 1,
                    tutorial_id: 1
                }],
                ["create", "submission", "with_users", "with_manuscript", {
                    assignment_id: 1,
                    tutorial_id: 2
                }]
            ]).then((lectures) => {
                cy.visit(`lectures/${lectures[0].id}`);
                cy.contains("Tutorien").click();
                cy.contains("Verschieben").click();
                cy.get('.select2-selection').click();
                cy.get('.select2-dropdown').contains(lectures[3].title).click();
                cy.get('.submission-actions > form > .mt-2 > .col-12 > .btn-primary').contains("Speichern").should("exist");
                cy.get('.submission-actions > form > .mt-2 > .col-12 > .btn-primary').contains("Speichern").click();
                cy.reload();
                cy.contains("Zu dieser Hausaufgabe liegen in diesem Tutorium keine Abgaben vor.").should("exist");
            });
        });
    });
    describe("Tutor", () => {
        beforeEach(() => {
            cy.app("clean");
            cy.appScenario("non_admin");
            cy.visit("/users/sign_in");
            cy.get('input[type="email"]').type("max@mampf.edu");
            cy.get('input[type="password"]').type("test123456");
            cy.get('input[type="submit"]').click();
        });
        it("can upload correction if assignment inactive", () => {
            cy.appFactories([
                ["create",
                    "lecture"
                ],
                ["create",
                    "lecture_user_join", {
                        user_id: 1,
                        lecture_id: 1
                    }
                ],
                ["create",
                    "tutorial", {
                        lecture_id: 1,
                        tutor_ids: [1]
                    }
                ],
                ["create",
                    "assignment", {
                        lecture_id: 1
                    }
                ],
                ["create",
                    "assignment", "inactive", {
                        lecture_id: 1
                    }
                ],
                ["create", "submission", "with_users", "with_manuscript", {
                    assignment_id: 1,
                    tutorial_id: 1
                }],
                ["create", "submission", "with_users", "with_manuscript", {
                    assignment_id: 2,
                    tutorial_id: 1
                }]
            ]).then((lectures) => {
                cy.visit(`lectures/${lectures[0].id}`);
                cy.contains("Tutorien").click();
                cy.contains("Tutorien").should("exist");
                cy.contains("Achtung").should("exist");
                cy.contains(lectures[3].title).click();
                cy.contains(lectures[4].title).click();
                cy.contains("Akzeptieren").click();
                cy.reload();
                cy.get(".correction-column").contains("Hochladen").click();
                const yourFixturePath = 'files/manuscript.pdf';
                cy.get(`#upload-correction-${lectures[6].id}`).attachFile(yourFixturePath);
                cy.contains("Upload").click();
                cy.get('.correction-upload > .mt-2 > .col-12 > .btn-primary').contains("Speichern").click();
                cy.reload();
                cy.get('.correction-action-area > [data-turbolinks="false"]').should("exist");
            });
        });
        it("can move submission", () => {
            cy.appFactories([
                ["create",
                    "lecture"
                ],
                ["create",
                    "lecture_user_join", {
                        user_id: 1,
                        lecture_id: 1
                    }
                ],
                ["create",
                    "tutorial", {
                        lecture_id: 1,
                        tutor_ids: [1]
                    }
                ],
                ["create",
                    "tutorial", {
                        lecture_id: 1
                    }
                ],
                ["create",
                    "assignment", {
                        lecture_id: 1
                    }
                ],
                ["create", "submission", "with_users", "with_manuscript", {
                    assignment_id: 1,
                    tutorial_id: 1
                }]
            ]).then((lectures) => {
                cy.visit(`lectures/${lectures[0].id}`);
                cy.contains("Tutorien").click();
                cy.contains("Verschieben").click();
                cy.get('.select2-selection').click();
                cy.get('.select2-dropdown').contains(lectures[3].title).click();
                cy.get('.submission-actions > form > .mt-2 > .col-12 > .btn-primary').contains("Speichern").should("exist");
                cy.get('.submission-actions > form > .mt-2 > .col-12 > .btn-primary').contains("Speichern").click();
                cy.reload();
                cy.contains("Zu dieser Hausaufgabe liegen in diesem Tutorium keine Abgaben vor.").should("exist");
            });
        });
    });
});