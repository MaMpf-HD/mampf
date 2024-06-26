describe("Thredded", function () {
  beforeEach(() => {
    cy.app("clean");
  });
  describe("Administration", () => {
    beforeEach(() => {
      cy.app("clean");
      cy.appScenario("admin");
      cy.visit("/users/sign_in");
      cy.get('input[type="email"]').type("administrator@mampf.edu");
      cy.get('input[type="password"]').type("test123456");
      cy.get('input[type="submit"]').click();
    });
    it("can access managment", () => {
      cy.appFactories([
        ["create", "course"],
        ["create",
          "lecture", "released_for_all", {
            teacher_id: 1,
            course_id: 1,
          },
        ], ["create", "lecture_user_join", {
          user_id: 1,
          lecture_id: 1,
        }],
      ]).then((records) => {
        cy.visit(`/lectures/${records[1].id}/edit`);
        cy.contains("Forum").click();
        cy.contains("Forum anlegen").click();
        cy.contains("Forum").click();
        cy.contains("Forum löschen").should("exist");
        cy.visit("/forum");
        cy.wait(100);
        cy.contains(records[0].title).click();
        cy.get('input[name="topic[title]').click().type("Test");
        cy.get('textarea[name="topic[content]').click().type("Test");
        cy.contains("Erstelle eine neue Diskussion").click();
        cy.visit("/forum");
        cy.contains("Verwaltung").click();
        cy.contains("Ausstehend").should("exist");
      });
    });
    it("can create forum", () => {
      cy.appFactories([
        ["create", "course"],
        ["create",
          "lecture", "released_for_all", {
            teacher_id: 1,
            course_id: 1,
          },
        ], ["create", "lecture_user_join", {
          user_id: 1,
          lecture_id: 1,
        }],
      ]).then((records) => {
        cy.visit(`/lectures/${records[1].id}/edit`);
        cy.contains("Forum").click();
        cy.contains("Forum anlegen").click();
        cy.contains("Forum").click();
        cy.contains("Forum löschen").should("exist");
        cy.visit("/forum");
        console.log(records[0]);
        cy.wait(100);
        cy.contains(records[0].title).should("exist");
      });
    });
    it("can delete forum", () => {
      cy.appFactories([
        ["create", "course"],
        ["create",
          "lecture", "released_for_all", "with_forum", {
            teacher_id: 1,
            course_id: 1,
          },
        ], ["create", "lecture_user_join", {
          user_id: 1,
          lecture_id: 1,
        }],
      ]).then((records) => {
        cy.visit(`/lectures/${records[1].id}/edit`);
        cy.contains("Forum").click();
        cy.contains("Forum löschen").click();
        cy.contains("Forum").click();
        cy.contains("Forum anlegen").should("exist");
      });
    });
  });
});
