describe("Submissions", () => {
  it("yeah dummy", () => {
    cy.createUserAndLogin("editor");
    cy.visit("/profile/edit/");
  });
});
