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
        /*it("can delete watchlis_entry from watchlist", () => {
            cy.appFactories([
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
                cy.get('.pl-3 > .btn').click();
                cy.contains(`${data[1].name}`).should("exist");
                cy.get('.alert-secondary').should("exist");
            });
        });*/
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
                cy.contains(`${data[1].name}`).should("exist");
                cy.get('.alert-secondary').should("exist");
            });
        });
        it("can create watchlist", () => {
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
				cy.get('div.text-light > .fas').click();
				cy.get('#openNewWatchlistForm').click();
				cy.get('#watchlistNameField').type("Lernliste");
				cy.get('#createWatchlistBtn').click();
				cy.get('#watchlistEntrySubmitButton').click();
                cy.wait(100);
                cy.get('#watchlistsIcon').click();
                cy.get('#card-title').should("exist");
			});
        });
    });
});