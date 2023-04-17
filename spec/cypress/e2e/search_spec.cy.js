describe("Media", () => {

    beforeEach(() => {
        cy.app("clean");
    });
    describe("Simple User",()=>{
		describe("Media search",()=>{
			beforeEach(() => {
				cy.app("clean");
				cy.appScenario("non_admin");
				cy.visit("/users/sign_in");
				cy.get('input[type="email"]').type("max@mampf.edu");
				cy.get('input[type="password"]').type("test123456");
				cy.get('input[type="submit"]').click();
			});
			/*it("can search released media",()=>{
				cy.appFactories([
					["create","lesson_medium", "with_manuscript","released"],
                	["create","lesson_medium", "with_manuscript"]
				]).then((records)=>{
					cy.get('#mediaSearchLink').click();
					cy.get('#collapseMediaSearch > .card-body > form > .row > .col-12 > .btn').click();
					cy.get('#media-search-results').get('.col-12 > .card').should('have.length',1);
				});
			});*/
			it("can filter for tags",()=>{
				cy.appFactories([
					["create","lesson_medium", "with_manuscript","released","with_tags"],
                	["create","lesson_medium", "with_manuscript","released"]
				]).then((records)=>{
					cy.get('#mediaSearchLink').click();
					cy.get('#media_fulltext').type(records[0].description);
					cy.wait(1000);
					cy.get('#collapseMediaSearch > .card-body > form > .row > .col-12 > .btn').click();
					cy.get('#media-search-results').get('.col-12 > .card').should('have.length',1);
					cy.get('#media-search-results').get('.col-12 > .card').contains(records[0].description);
				});
			});			
		});
	});
});