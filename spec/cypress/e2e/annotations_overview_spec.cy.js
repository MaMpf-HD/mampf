import FactoryBot from "../support/factorybot";
import { hexToRgb } from "../support/utility";

const CARD_SELECTOR = "annotation-overview-card";

describe("Annotations Overview", () => {
  describe("User annotation card", () => {
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
          { medium_id: this.medium1.id, user_id: this.genericUser.id }).as("annotation1");
        FactoryBot.create("annotation", "with_text",
          { medium_id: this.medium2.id, user_id: this.genericUser.id }).as("annotation2");
        FactoryBot.create("annotation", "with_text",
          { medium_id: this.medium3.id, user_id: this.genericUser.id }).as("annotation3");
        FactoryBot.create("annotation", "with_text",
          { medium_id: this.medium3.id, user_id: this.genericUser.id }).as("annotation4");
      });
    });

    it("contains the medium title and the comment", function () {
      cy.visit("/annotations/overview");
      [
        { title: MEDIUM_TITLE_1, comment: this.annotation1.comment },
        { title: MEDIUM_TITLE_2, comment: this.annotation2.comment },
        { title: MEDIUM_TITLE_3, comment: this.annotation3.comment },
        { title: MEDIUM_TITLE_3, comment: this.annotation4.comment },
      ].forEach((test, i) => {
        cy.getBySelector(CARD_SELECTOR).eq(i).as("card");
        cy.get("@card").children().first().should("contain", test.title);
        cy.get("@card").children().eq(1).should("contain", test.comment);
      });
    });

    it("has border according to annotation color", function () {
      cy.visit("/annotations/overview");
      [this.annotation1, this.annotation2, this.annotation3, this.annotation4]
        .forEach((annotation, i) => {
          cy.getBySelector(CARD_SELECTOR).eq(i).as("card");
          const colorExpected = hexToRgb(annotation.color);
          cy.get("@card").should("have.css", "border-color", colorExpected);
        });
    });

    it("is grouped by lecture", function () {
      cy.visit("/annotations/overview");
      [LECTURE_TITLE_1, LECTURE_TITLE_2, LECTURE_TITLE_2, LECTURE_TITLE_2]
        .forEach((title, i) => {
          cy.getBySelector(CARD_SELECTOR).eq(i)
            .parents(".accordion-collapse").siblings(".accordion-header")
            .should("contain", title);
        });
    });

    it("redirects to medium video when clicked", function () {
      [
        { medium: this.medium1, annotation: this.annotation1 },
        { medium: this.medium2, annotation: this.annotation2 },
        { medium: this.medium3, annotation: this.annotation3 },
        { medium: this.medium3, annotation: this.annotation4 },
      ].forEach((test, i) => {
        cy.visit("/annotations/overview");
        cy.getBySelector(CARD_SELECTOR).eq(i).as("card");
        cy.get("@card").parents(".accordion-collapse").siblings(".accordion-header").click();
        cy.get("@card").click();

        cy.url().should("contain", `/media/${test.medium.id}`);
        let timestamp = `0:00:${test.annotation.timestamp.seconds}`;
        cy.getBySelector("current-time").should("contain", timestamp);
        cy.getBySelector("annotation-comment").should("contain", test.annotation.comment);
      });
    });
  });
});
