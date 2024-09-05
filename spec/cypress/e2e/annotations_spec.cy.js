import FactoryBot from "../support/factorybot";

function createLectureLessonMedium(context, teacher) {
  // Lecture
  FactoryBot.create("lecture_with_sparse_toc", "with_title",
    { title: "Groundbreaking lecture", teacher_id: teacher.id }).as("lecture");

  // Lesson
  cy.then(() => {
    FactoryBot.create("valid_lesson", { lecture_id: context.lecture.id }).as("lesson");
  });

  // Medium
  cy.then(() => {
    FactoryBot.create("lesson_medium", "with_video", "released",
      "with_lesson_by_id", { lesson_id: context.lesson.id, description: "Soil medium" })
      .as("medium");
  });
}

describe("Annotations visibility", () => {
  context("when teacher disables annotation sharing with teachers", () => {
    it("annotations published before that are still visible to the teacher", function () {
      cy.createUser("generic").as("user");
      cy.createUserAndLogin("teacher").then(teacher => createLectureLessonMedium(this, teacher));

      cy.then(() => {
        // Create new annotation
        FactoryBot.create("annotation", "with_text", "shared_with_teacher",
          { medium_id: this.medium.id, user_id: this.user.id }).as("annotation");

        // Disable annotation sharing in lecture settings
        cy.visit(`/lectures/${this.lecture.id}/edit#communication`);
        cy.getBySelector("annotation-lecture-settings")
          .should("be.visible")
          .find("input[value=0]").should("have.length", 1).click();

        // Click on submit button to save changes
        cy.intercept("POST", `/lectures/${this.lecture.id}`).as("lectureUpdate");
        cy.getBySelector("lecture-pane-communication")
          .find("input[type=submit]").should("have.length", 1).click();
        cy.wait("@lectureUpdate");

        // Make sure that changes were really saved
        cy.reload();
        cy.getBySelector("annotation-lecture-settings")
          .should("be.visible").then(($form) => {
            cy.wrap($form).find("input[value=0]").should("be.checked");
            cy.wrap($form).find("input[value=1]").should("not.be.checked");
          });
      });

      cy.then(() => {
        cy.visit(`/media/${this.medium.id}/feedback`);

        // Annotation is visible
        cy.getBySelector("feedback-markers")
          .children().should("have.length", 1)
          .click({ force: true });

        // Annotation can be opened in sidebar
        cy.getBySelector("annotation-caption").then(($sideBar) => {
          cy.i18n(`admin.annotation.${this.annotation.category}`).then((category) => {
            cy.wrap($sideBar).children().first().should("contain", category);
          });
          cy.wrap($sideBar).children().eq(1).should("contain", this.annotation.comment);
        });
      });
    });
  });
});
