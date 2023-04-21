describe('My First Test', function() {
    it('visit root', function() {
  
      // Visit the application under test
      cy.visit('/');
  
      cy.contains("MaMpf");
      cy.screenshot();
    });
  });
