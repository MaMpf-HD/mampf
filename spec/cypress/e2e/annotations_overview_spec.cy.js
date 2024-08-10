import FactoryBot from "../support/factorybot";

describe("Annotations Overview", () => {
  describe("Generic user", () => {
    beforeEach(function () {
      cy.createUser("teacher");
      cy.createUser("admin");
      cy.createUserAndLogin("generic").as("genericUser");

      cy.then(() => {
        FactoryBot.createNoValidate("lesson_medium", "with_video", "released").then((medium) => {
          FactoryBot.create("annotation", "with_text",
            { medium_id: medium.id, user_id: this.genericUser.id });
          FactoryBot.create("annotation", "with_text",
            { medium_id: medium.id, user_id: this.genericUser.id });
        });

        FactoryBot.createNoValidate("lesson_medium", "with_video", "released").then((medium) => {
          FactoryBot.create("annotation", "with_text",
            { medium_id: medium.id, user_id: this.genericUser.id });
        });
      });
    });

    it("can view own annotations", function () {
      cy.visit("/annotations/overview");
    });
  });
});
