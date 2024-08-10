import FactoryBot from "../support/factorybot";

describe("Annotations Overview", () => {
  describe("Annotation cards", () => {
    const CARD_SELECTOR = "annotation-overview-card";

    const LECTURE_TITLE_1 = "SageMath";
    const MEDIUM_TITLE_1 = "Math Intro";
    const LECTURE_TITLE_2 = "Lean4";
    const MEDIUM_TITLE_2 = "Intro";
    const MEDIUM_TITLE_3 = "Continuous functions";

    beforeEach(function () {
      cy.createUser("teacher");
      cy.createUser("admin");
      cy.createUserAndLogin("generic").as("genericUser");

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

      // Annotations
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

    it("contain the medium title in their header", function () {
      cy.visit("/annotations/overview");
      cy.getBySelector(CARD_SELECTOR).then(($cards) => {
        cy.wrap($cards).should("have.length", 4);
        cy.wrap($cards).eq(0).children().first().should("contain", MEDIUM_TITLE_1);
        cy.wrap($cards).eq(1).children().first().should("contain", MEDIUM_TITLE_2);
        cy.wrap($cards).eq(2).children().first().should("contain", MEDIUM_TITLE_3);
        cy.wrap($cards).eq(3).children().first().should("contain", MEDIUM_TITLE_3);
      });
    });

    it("are grouped by lecture", function () {
      cy.visit("/annotations/overview");
      cy.getBySelector(CARD_SELECTOR).then(($cards) => {
        cy.wrap($cards).eq(0)
          .parents(".accordion-collapse").siblings(".accordion-header")
          .should("contain", LECTURE_TITLE_1);
        cy.wrap($cards).eq(1)
          .parents(".accordion-collapse").siblings(".accordion-header")
          .should("contain", LECTURE_TITLE_2);
        cy.wrap($cards).eq(2)
          .parents(".accordion-collapse").siblings(".accordion-header")
          .should("contain", LECTURE_TITLE_2);
        cy.wrap($cards).eq(3)
          .parents(".accordion-collapse").siblings(".accordion-header")
          .should("contain", LECTURE_TITLE_2);
      });
    });
  });
});
