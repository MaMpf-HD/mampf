import FactoryBot from "../support/factorybot";
import { hexToRgb } from "../support/utility";

const CARD_SELECTOR = "annotation-overview-card";

const LECTURE_TITLE_1 = "SageMath";
const MEDIUM_TITLE_1 = "Intro modules";
const LECTURE_TITLE_2 = "Lean4";
const MEDIUM_TITLE_2 = "Intro operators";
const MEDIUM_TITLE_3 = "Continuous functions";

function createAnnotationScenario(context, userRole = "student") {
  if (userRole === "teacher") {
    cy.createUser("generic").as("genericUser");
    cy.createUserAndLogin("teacher").as("user");
  }
  else {
    cy.createUser("teacher").as("teacherUser");
    cy.createUserAndLogin("generic").as("user");
  }

  // Lectures
  cy.then(() => {
    // a user is considered a teacher only iff they have given any lecture
    const teacherUser = userRole === "teacher" ? context.user : context.teacherUser;
    FactoryBot.create("lecture_with_sparse_toc", "with_title", "with_teacher_by_id",
      { title: LECTURE_TITLE_1, teacher_id: teacherUser.id }).as("lectureSage");
    FactoryBot.create("lecture_with_sparse_toc", "with_title", "with_teacher_by_id",
      { title: LECTURE_TITLE_2, teacher_id: teacherUser.id }).as("lectureLean");
  });

  // Lessons
  cy.then(() => {
    FactoryBot.create("valid_lesson", { lecture_id: context.lectureSage.id }).as("lesson1");
    FactoryBot.create("valid_lesson", { lecture_id: context.lectureLean.id }).as("lesson2");
    FactoryBot.create("valid_lesson", { lecture_id: context.lectureLean.id }).as("lesson3");
  });

  // Media
  cy.then(() => {
    FactoryBot.create("lesson_medium", "with_video", "released",
      "with_lesson_by_id", { lesson_id: context.lesson1.id, description: MEDIUM_TITLE_1 })
      .as("medium1");
    FactoryBot.create("lesson_medium", "with_video", "released",
      "with_lesson_by_id", { lesson_id: context.lesson2.id, description: MEDIUM_TITLE_2 })
      .as("medium2");
    FactoryBot.create("lesson_medium", "with_video", "released",
      "with_lesson_by_id", { lesson_id: context.lesson3.id, description: MEDIUM_TITLE_3 })
      .as("medium3");
  });

  // Annotations
  cy.then(() => {
    FactoryBot.create("annotation", "with_text",
      { medium_id: context.medium1.id, user_id: context.user.id }).as("annotation1");
    FactoryBot.create("annotation", "with_text",
      { medium_id: context.medium2.id, user_id: context.user.id }).as("annotation2");
    FactoryBot.create("annotation", "with_text",
      { medium_id: context.medium3.id, user_id: context.user.id }).as("annotation3");
    FactoryBot.create("annotation", "with_text",
      { medium_id: context.medium3.id, user_id: context.user.id }).as("annotation4");
  });
}

describe("Annotation section", () => {
  it("shows only *own* annotations for generic user", function () {
    cy.createUserAndLogin("generic");

    cy.i18n("admin.annotation.your_annotations").as("yourAnnotations");
    cy.i18n("admin.annotation.students_annotations").as("studentsAnnotations");

    cy.then(() => {
      cy.visit("/annotations");
      cy.getBySelector("annotations-container").should("contain", this.yourAnnotations);
      cy.getBySelector("annotations-container").should("not.contain", this.studentsAnnotations);
    });
  });

  it("shows both *own* and *students'* annotations for teacher", function () {
    cy.createUserAndLogin("teacher").as("teacher");
    cy.then(() => {
      // a user is considered a teacher only iff they have given any lecture
      FactoryBot.create("lecture", "with_teacher_by_id", { teacher_id: this.teacher.id });
    });

    cy.i18n("admin.annotation.your_annotations").as("yourAnnotations");
    cy.i18n("admin.annotation.students_annotations").as("studentsAnnotations");

    cy.then(() => {
      cy.visit("/annotations");
      cy.getBySelector("annotations-container").should("contain", this.yourAnnotations);
      cy.getBySelector("annotations-container").should("contain", this.studentsAnnotations);
    });
  });
});

describe("User annotation card", () => {
  beforeEach(function () {
    createAnnotationScenario(this);
  });

  it("is grouped by lecture", function () {
    cy.visit("/annotations");
    // lecture title 1 comes last because we sort according to lecture.updated_at
    // and lecture 2 is created after lecture 1
    [LECTURE_TITLE_2, LECTURE_TITLE_2, LECTURE_TITLE_2, LECTURE_TITLE_1]
      .forEach((title, i) => {
        cy.getBySelector(CARD_SELECTOR).eq(i)
          .parents(".accordion-collapse").siblings(".accordion-header")
          .should("contain", title);
      });
  });

  it("renders math content", function () {
    cy.visit("/annotations");
    cy.getBySelector(CARD_SELECTOR).last().then(($card) => {
      cy.wrap($card).find(".katex").should("not.exist");
    });

    // Create annotation with math content
    FactoryBot.create("annotation", "with_text",
      { medium_id: this.medium1.id, user_id: this.user.id,
        comment: "This is a math annotation: $\\frac{1}{2}$",
      }).as("annotationWithMath");

    cy.then(() => {
      cy.visit("/annotations");
      cy.getBySelector(CARD_SELECTOR).last().then(($card) => {
        cy.wrap($card).find(".katex").should("exist");
      });
    });
  });

  it.only("contains medium and annotation information", function () {
    cy.visit("/annotations");
    console.log(MEDIUM_TITLE_3);
    [
      { title: MEDIUM_TITLE_3, annotation: this.annotation4, lesson: this.lesson3 },
      { title: MEDIUM_TITLE_3, annotation: this.annotation3, lesson: this.lesson3 },
      { title: MEDIUM_TITLE_2, annotation: this.annotation2, lesson: this.lesson2 },
      { title: MEDIUM_TITLE_1, annotation: this.annotation1, lesson: this.lesson1 },
    ].forEach((test, i) => {
      cy.getBySelector(CARD_SELECTOR).eq(i).as("card");

      // Lesson date
      const expectedDate = this.user.locale === "de"
        ? new Date(test.lesson.date).toLocaleDateString("de-DE", {
          year: "numeric",
          month: "2-digit",
          day: "2-digit",
        })
        : test.lesson.date;
      cy.get("@card").children().first().should("contain", expectedDate);

      // Medium title
      cy.get("@card").children().first().should("contain", test.title);

      // Annotation category & comment
      cy.get("@card").children().first().invoke("text").then((categoryText) => {
        expect(categoryText.toLowerCase()).to.contain(test.annotation.category);
      });
      cy.get("@card").children().eq(1).should("contain", test.annotation.comment);
    });
  });

  it("has border according to annotation color", function () {
    cy.visit("/annotations");
    [this.annotation1, this.annotation2, this.annotation3, this.annotation4]
      .forEach((annotation, i) => {
        cy.getBySelector(CARD_SELECTOR).eq(i).as("card");
        const colorExpected = hexToRgb(annotation.color);
        cy.get("@card").should("have.css", "border-color", colorExpected);
      });
  });

  it("redirects to medium video when clicked", function () {
    [
      { medium: this.medium1, annotation: this.annotation1 },
      { medium: this.medium2, annotation: this.annotation2 },
      { medium: this.medium3, annotation: this.annotation3 },
      { medium: this.medium3, annotation: this.annotation4 },
    ].forEach((test, i) => {
      cy.visit("/annotations");
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

describe("Student annotation card (shared with teacher)", () => {
  beforeEach(function () {
    createAnnotationScenario(this, "teacher");

    cy.then(() => {
      FactoryBot.create("annotation", "with_text", "shared_with_teacher",
        { medium_id: this.medium1.id, user_id: this.genericUser.id }).as("annotation1FromStudent");
      FactoryBot.create("annotation", "with_text", "shared_with_teacher",
        { medium_id: this.medium1.id, user_id: this.genericUser.id }).as("annotation2FromStudent");
      FactoryBot.create("annotation", "with_text", "shared_with_teacher",
        { medium_id: this.medium3.id, user_id: this.genericUser.id }).as("annotation3FromStudent");
    });
  });

  it("has border according to annotation *category*, not its color", function () {
    const colorMap = {
      note: "#f78f19",
      content: "#A333C8",
      presentation: "#2185D0",
      mistake: "#fc1461",
    };
    cy.visit("/annotations");
    [this.annotation1FromStudent, this.annotation2FromStudent, this.annotation3FromStudent]
      .forEach((annotation, i) => {
        cy.getBySelector(CARD_SELECTOR).eq(i).as("card");
        const colorExpected = hexToRgb(colorMap[annotation.category]);
        cy.get("@card").should("have.css", "border-color", colorExpected);
      });
  });

  it("redirects to medium *feedback* video when clicked", function () {
    [
      { medium: this.medium1, annotation: this.annotation1FromStudent },
      { medium: this.medium1, annotation: this.annotation2FromStudent },
      { medium: this.medium3, annotation: this.annotation3FromStudent },
    ].forEach((test, i) => {
      cy.visit("/annotations");
      cy.getBySelector(CARD_SELECTOR).eq(i).as("card");
      cy.get("@card").parents(".accordion-collapse").siblings(".accordion-header").click();
      cy.get("@card").click();

      cy.url().should("contain", `/media/${test.medium.id}/feedback`);
      let timestamp = `0:00:${test.annotation.timestamp.seconds}`;
      cy.getBySelector("current-time").should("contain", timestamp);
      cy.getBySelector("annotation-comment").should("contain", test.annotation.comment);
    });
  });
});
