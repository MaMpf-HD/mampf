describe("Watchlists", () => {

    beforeEach(() => {
        cy.app("clean");
    });
    describe("User", () => {
        beforeEach(() => {
            cy.app("clean");
            cy.appScenario("non_admin");
            cy.visit("/users/sign_in");
            cy.get('input[type="email"]').type("max@mampf.edu");
            cy.get('input[type="password"]').type("test123456");
            cy.get('input[type="submit"]').click();
        });
        it("can create and add to watchlist in lecture", () => {
			cy.appFactories([
                ["create", "lecture_medium", "with_manuscript", "released"],
                ["create",
                    "lecture_user_join", {
                        user_id: 1,
                        lecture_id: 1
                    }
                ]
			]).then((data) => {
				cy.visit(`lectures/${data[0].id}`);
				cy.get('.nav > :nth-child(6) > .nav-link').click();
				cy.get('div.text-light > .fa-list').click();
				cy.get('#openNewWatchlistForm').click();
				cy.get('#watchlistNameField').type('Lernliste');
				cy.get('#createWatchlistBtn').click();
				cy.get('#watchlistEntrySubmitButton').click();
                cy.wait(100);
                cy.get('div.text-light > .fa-list').click();
                cy.get('#watchlistEntrySubmitButton').click();
                cy.get('.invalid-feedback').should('exist');
                cy.wait(200);
                cy.get('.close > span').click();
                cy.wait(100);
                cy.get('#watchlistsIcon').click();
                cy.get('#card-title').should('exist');
			});
        });
        it("can change watchlist", () => {
            cy.appFactories([
                ["create", "watchlist", {
                    user_id: 1
                }]
            ]).then((data) => {
                cy.visit(`watchlists/1`);
                cy.get('#changeWatchlistBtn').click();
                cy.get('#watchlistNameField').should('have.value', `${data[0].name}`);
                cy.get('#watchlistNameField').clear();
                cy.get('#watchlistNameField').type('Lernliste');
                cy.wait(100);
                cy.get('#watchlistDescriptionField').type('Dies ist eine Lernliste.');
                cy.get('#confirmChangeWatchlistButton').click();
                cy.get('#watchlistButton').contains('Lernliste');
                cy.get('#descriptionButton').click();
                cy.get('.card').contains('Dies ist eine Lernliste.')
            });
        })
        it("can create new watchlist in watchlist view", () => {
			cy.appFactories([
			]).then((data) => {
				cy.get('#watchlistsIcon').click();
                cy.get('#openNewWatchlistForm').click();
                cy.get('#watchlistNameField').type('Lernliste');
                cy.get('#newWatchlistButton').click();
                cy.wait(100);
                cy.get('#watchlistButton').contains('Lernliste');
			});
        });
        it("can use bookmark", () => {
			cy.appFactories([
                ["create", "watchlist", {
                    user_id: 1
                }],
                ["create", "watchlist_entry", "with_medium", {
                    watchlist_id: 1
                }],
                ["create",
                    "lecture_user_join", {
                        user_id: 1,
                        lecture_id: 1
                    }
                ]
			]).then((data) => {
				cy.visit('lectures/1');
				cy.get('.nav > :nth-child(6) > .nav-link').click();
                cy.get('.fa-bookmark').click();
                cy.get('#watchlistButton').contains(`${data[0].name}`).should('exist');
			});
        });
        it("can change visibility of watchlist", () => {
            cy.appFactories([
                ["create", "watchlist", {
                    user_id: 1
                }]
            ]).then((data) => {
                cy.visit(`watchlists/1`);
                cy.get('#watchlistVisiblityCheck').should('not.be.checked');
                cy.get('#watchlistVisiblityCheck').click();
                cy.reload();
                cy.get('#watchlistVisiblityCheck').should('be.checked');
            });
        });
        it("can view public watchlist of other user", () => {
            cy.appFactories([
                ["create", "watchlist", "with_user", {
                    public: true
                }]
            ]).then((data) => {
                cy.visit(`watchlists/1`);
                cy.get('#watchlistButton').should('exist');
            });
        });
        it("can not view private watchlist of other user", () => {
            cy.appFactories([
                ["create", "watchlist", "with_user", {
                    public: false
                }]
            ]).then((data) => {
                cy.visit(`watchlists/1`);
                cy.get(':nth-child(3) > .row > .col-12 > :nth-child(2)').contains('Du bist nicht berechtigt').should('exist');
            });
        });
        it("can filter watchlist_entries", () => {
            cy.appFactories([
                ["create", "watchlist", {
                    user_id: 1
                }],
                ["create_list", "watchlist_entry", 5, "with_medium", {
                    watchlist_id: 1
                }]
            ]).then((data) => {
                cy.get('#watchlistsIcon').click();
                cy.get('#reverseButton').click();
                cy.wait(100);
                cy.get('#perPageButton').click();
                cy.get('[href="/watchlists/1?page=1&per=3&reverse=true"]').click();
                cy.wait(100);
                cy.get('#allButton').click();
                cy.get('#watchlistButton').should('exist');
                cy.get('.active > .page-link').should('not.exist');
            });
        });
        it("can drag and drop watchlist_entry", () => {
            cy.appFactories([
                ["create", "watchlist", {
                    user_id: 1
                }],
                ["create", "watchlist_entry", "with_medium", {
                    watchlist_id: 1
                }],
                ["create", "watchlist_entry", "with_medium", {
                    watchlist_id: 1
                }],
                ["create", "watchlist_entry", "with_medium", {
                    watchlist_id: 1
                }]
            ]).then((data) => {
                cy.get('#watchlistsIcon').click();
                cy.get(':nth-child(1) > .card > .card-header').trigger('mousedown', { which: 1 });
                cy.wait(100);
                cy.get(':nth-child(3) > .card > .card-header').trigger('mousemove', 0, 0);
                cy.wait(100);
                cy.get(':nth-child(1) > .card > .card-header').trigger('mouseup');
                cy.reload();
                cy.wait(100);
                cy.get(':nth-child(1) > .card > .card-header > :nth-child(1) > #card-title').contains(`${data[2].medium_id}`).should('exist');
            });
        });
        it("can delete watchlist_entry from watchlist", () => {
            cy.appFactories([
                ["create", "watchlist", {
                    user_id: 1
                }],
                ["create", "watchlist_entry", "with_medium", {
                    watchlist_id: 1
                }]
            ]).then((data) => {
                cy.get('#watchlistsIcon').click();
                cy.get('div.text-light > .fas').click();
                cy.get('.alert-secondary').should('exist');
                cy.get('#watchlistButton').contains(`${data[0].name}`).should('exist');
            });
        });
        it("can delete watchlist", () => {
            cy.appFactories([
                ["create", "lecture_medium", "released"],
                ["create", "watchlist", {
                    user_id: 1
                }],
                ["create", "watchlist", {
                    user_id: 1
                }]
            ]).then((data) => {
                cy.get('#watchlistsIcon').click();
                cy.contains(`${data[1].name}`).click();
                cy.contains(`${data[2].name}`).click();
                cy.wait(100);
                cy.get('#deleteWatchlistBtn').click();
                cy.contains(`${data[1].name}`).should('exist');
                cy.get('.alert-secondary').should('exist');
            });
        });
    });
});