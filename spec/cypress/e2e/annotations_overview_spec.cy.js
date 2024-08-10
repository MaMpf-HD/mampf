import FactoryBot from "../support/factorybot";

describe("Annotations Overview", () => {
  describe("Generic user", () => {
    beforeEach(function () {
      cy.createUser("teacher");
      cy.createUser("admin");
      cy.createUserAndLogin("generic").as("genericUser");

      const LECTURE_TITLE_1 = "SageMath";
      const MEDIUM_TITLE_1 = "Intro to SageMath";
      const LECTURE_TITLE_2 = "Lean4";
      const MEDIUM_TITLE_2 = "Intro to Lean4";
      const MEDIUM_TITLE_3 = "Continuous functions in Lean4";

      // Lectures
      cy.then(() => {
        FactoryBot.create("lecture_with_sparse_toc",
          "with_title", { title: LECTURE_TITLE_1 }).as("lectureSage");
        FactoryBot.create("lecture_with_sparse_toc",
          "with_title", { title: LECTURE_TITLE_2 }).as("lectureLean");
      });

      // Lessons
      cy.then(() => {
        FactoryBot.create("valid_lesson", { lecture_id: this.lectureSage.id }).as("lesson1");
        FactoryBot.create("valid_lesson", { lecture_id: this.lectureLean.id }).as("lesson2");
        FactoryBot.create("valid_lesson", { lecture_id: this.lectureLean.id }).as("lesson3");
      });

      // Media
      cy.then(() => {
        FactoryBot.create("lesson_medium", "with_video", "released",
          "with_lesson_by_id", { lesson_id: this.lesson1.id, description: MEDIUM_TITLE_1 })
          .as("medium1");
        FactoryBot.create("lesson_medium", "with_video", "released",
          "with_lesson_by_id", { lesson_id: this.lesson2.id, description: MEDIUM_TITLE_2 })
          .as("medium2");
        FactoryBot.create("lesson_medium", "with_video", "released",
          "with_lesson_by_id", { lesson_id: this.lesson3.id, description: MEDIUM_TITLE_3 })
          .as("medium3");
      });

      cy.then(() => {
        FactoryBot.create("annotation", "with_text",
          { medium_id: this.medium1.id, user_id: this.genericUser.id });
        FactoryBot.create("annotation", "with_text",
          { medium_id: this.medium2.id, user_id: this.genericUser.id });
        FactoryBot.create("annotation", "with_text",
          { medium_id: this.medium3.id, user_id: this.genericUser.id });
        FactoryBot.create("annotation", "with_text",
          { medium_id: this.medium3.id, user_id: this.genericUser.id });
      });
    });

    it("can view own annotations", function () {
      cy.visit("/annotations/overview");
    });
  });
});
