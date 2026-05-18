describe("Courses", function () {
  beforeEach(() => {
    cy.app("clean");
    cy.appScenario("setup");
  });
  describe("admin user", () => {
    beforeEach(() => {
      cy.appScenario("admin");
      cy.visit("/users/sign_in");
      cy.get('input[type="email"]').type("administrator@mampf.edu");
      cy.get('input[type="password"]').type("test123456");
      cy.get('input[type="submit"]').click();
    });
    it("can add tag to course", () => {
      cy.appFactories([
        ["create", "course"],
      ]).then((_records) => {
        cy.visit("/courses/1/edit");
        cy.get("#new-tag-button").click();
        cy.get("#tag_notions_attributes_0_title").type("Geometrie");
        cy.wait(100);
        cy.get("#tag_notions_attributes_1_title").type("Geometry");
        cy.get(".col-12 > .btn-primary").click();
        cy.wait(100);
        cy.contains("Geometrie");
      });
    });
    it("can set editor in course", () => {
      cy.appFactories([
        ["create", "course"],
      ]).then((_records) => {
        cy.visit("/courses/1/edit");
        cy.get("#course_editor_ids-ts-control").click();
        cy.get("#course_editor_ids-ts-control").type("ad");
        cy.contains("administrator@mampf.edu").click();
        cy.get(".btn-primary").click();
        cy.contains("Admin");
      });
    });
    it("can create module", () => {
      cy.visit("/administration");
      cy.get('i[title="Modul anlegen"]').click();
      cy.get('input[name="course[title]"]').type("Lineare Algebra I");
      cy.get('input[name="course[short_title]"]').type("LA I");
      cy.get('input[type="submit"]').click();
      // cy.visit('/administration');
      cy.contains("Lineare Algebra I").should("exist");
    });
    it("can set course image", () => {
      cy.appFactories([
        ["create", "course"],
        ["create", "term"],
        ["create", "lecture", { term_id: 1, course_id: 1 }],
      ]).then((records) => {
        cy.visit(`/courses/${records[0].id}/edit`);
        cy.contains("Bild").should("exist");
        cy.get("#image_heading").contains("Ein-/Ausklappen").click();
        const yourFixturePath = "cypress/fixtures/files/image.png";
        cy.get("#upload-image").selectFile(yourFixturePath, { force: true });
        cy.contains("Upload").click();
        cy.wait(100);
        cy.contains("Speichern").click();
        cy.get("#image_heading").contains("Ein-/Ausklappen").click();
        cy.contains("image.png").should("exist");
      });
    });
    it("can create lecture", () => {
      cy.appFactories([
        ["create", "course"],
        ["create", "term"],
        ["create", "editable_user_join", {
          editable_id: 1,
          editable_type: "Course",
          user_id: 1,
        }],
      ]).then((records) => {
        cy.visit("/administration");
        cy.get('a[title="Veranstaltung anlegen"]').click();

        cy.get("#lecture_course_id-ts-control").type(records[0].title).type("{enter}");
        cy.get("div#new-lecture-area").contains("Speichern").click();
        cy.contains(records[0].title).should("exist");
        cy.contains(`${records[1].season} ${records[1].year}`).should("exist");
      });
    });
  });
  describe("teacher", () => {
    beforeEach(() => {
      cy.appScenario("non_admin");
      cy.visit("/users/sign_in");
      cy.get('input[type="email"]').type("max@mampf.edu");
      cy.get('input[type="password"]').type("test123456");
      cy.get('input[type="submit"]').click();
    });
    it("can subscribe to unpublished on page", () => {
      cy.appFactories([
        ["create", "lecture", {
          teacher_id: 1,
        }],
      ]).then((courses) => {
        cy.visit(`/lectures/${courses[0].id}`);
        cy.contains("Achtung").should("exist");
        cy.contains("Veranstaltung abonnieren").click();
        cy.contains("Vorlesungsinhalt").should("exist");
      });
    });
  });
  describe("simple user", () => {
    beforeEach(() => {
      cy.appScenario("non_admin");
      cy.visit("/users/sign_in");
      cy.get('input[type="email"]').type("max@mampf.edu");
      cy.get('input[type="password"]').type("test123456");
      cy.get('input[type="submit"]').click();
    });
    it("can subscribe", () => {
      // call a scenario in app_commands/scenarios

      cy.appFactories([
        ["create_list", "lecture", 6, "released_for_all"],
      ]).then((_records) => {
        cy.visit("/main/start");
        // cy.get('input[name="search[fulltext]"]').type(records[0][0].title)
        cy.contains("Veranstaltungssuche").click();
        cy.contains("Suche").click();
        cy.get('[title="abonnieren"]').first().click();
        cy.get('[title="abbestellen"]').should("exist");
      });
    });
    it("can subscribe on page", () => {
      cy.appFactories([
        ["create", "lecture", "released_for_all"],
      ]).then((courses) => {
        cy.visit(`/lectures/${courses[0].id}`);
        cy.contains("Achtung").should("exist");
        cy.contains("Veranstaltung abonnieren").click();
        cy.contains("Vorlesungsinhalt").should("exist");
      });
    });
    it("is blocked to subscribe on page", () => {
      cy.appFactories([
        ["create", "lecture", {
          released: "locked",
          passphrase: "passphrase",
        }],
      ]).then((courses) => {
        cy.visit(`/lectures/${courses[0].id}`);
        cy.contains("Achtung").should("exist");
        cy.contains("Veranstaltung abonnieren").click();
        cy.contains("Vorlesungsinhalt").should("not.exist");
        cy.contains("Achtung").should("exist");
      });
    });
    it("can not subscribe on page to unpublished", () => {
      cy.appFactories([
        ["create", "lecture"],
      ]).then((courses) => {
        cy.visit(`/lectures/${courses[0].id}`);
        cy.contains("Du bist nicht berechtigt").should("exist");
      });
    });
  });
});
