describe("Submissions", () => {
  it("yeah dummy", () => {
    console.log("test submission");
    cy.appScenario("editor");
    cy.login({ email: "editor@mampf.edu", password: "test123456" });
    cy.visit("/profile/edit/");
  });
});
