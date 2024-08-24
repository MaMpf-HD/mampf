import FactoryBot from "../support/factorybot";

function createRedemptionScenario(context) {
  cy.createUser("teacher").as("teacher");
  cy.createUserAndLogin("generic").as("user");

  cy.then(() => {
    FactoryBot.create("lecture", { teacher_id: context.teacher.id }).as("lecture");
  });

  cy.then(() => {
    FactoryBot.create("voucher", { lecture_id: context.lecture.id }).as("voucher");
  });

  cy.then(() => {
    cy.visit("/profile/edit");
  });

  cy.i18n("profile.redeem_voucher").as("redeem_voucher");
}

function submitVoucher(voucher) {
  cy.getBySelector("secure-hash-input").type(voucher.secure_hash);
  cy.getBySelector("verify-voucher-submit").click();
}

function verifyVoucherRedemptionText() {
  cy.getBySelector("redeem-voucher-text").should("be.visible");
}

function verifyNoTutorialsYetMessage(context) {
  cy.i18n("profile.no_tutorials_yet").as("no_tutorials_yet");

  cy.then(() => {
    cy.getBySelector("redeem-voucher-card").should("contain", context.no_tutorials_yet);
    cy.getBySelector("redeem-voucher-btn").should("be.visible");
  });
}

function redeemVoucherToBecomeTutor(context) {
  cy.i18n("controllers.become_tutor_success").as("become_tutor_success");
  cy.getBySelector("redeem-voucher-btn").click();
  cy.then(() => {
    cy.getBySelector("flash-notice").should("be.visible").and("contain", context.become_tutor_success);
  });
}

function createTutorials(context) {
  FactoryBot.create("tutorial", { lecture_id: context.lecture.id }).as("tutorial1");
  FactoryBot.create("tutorial", { lecture_id: context.lecture.id }).as("tutorial2");
  FactoryBot.create("tutorial", { lecture_id: context.lecture.id }).as("tutorial3");
}

function createTutorialsWithTutor(context, tutor) {
  console.log(tutor.id);
  FactoryBot.create("tutorial", { lecture_id: context.lecture.id, tutor_ids: [tutor.id] }).as("tutorial1");
  FactoryBot.create("tutorial", { lecture_id: context.lecture.id, tutor_ids: [tutor.id] }).as("tutorial2");
  FactoryBot.create("tutorial", { lecture_id: context.lecture.id, tutor_ids: [tutor.id] }).as("tutorial3");
}

function selectTutorialsAndSubmit(tutorialIds) {
  const tutorialIdsAsStrings = tutorialIds.map(id => id.toString());

  cy.getBySelector("claim-select").should("be.visible");
  cy.getBySelector("claim-select").select(tutorialIdsAsStrings, { force: true });
  cy.getBySelector("claim-submit").click();
  cy.getBySelector("flash-notice").should("be.visible");
}

function verifyTutorialRowsContainTutorName(context, tutorialIds) {
  cy.getBySelector("tutorial-row").should("have.length", 3).each(($el) => {
    const dataId = parseInt($el.attr("data-id"), 10);
    if (tutorialIds.includes(dataId)) {
      cy.wrap($el).should("contain", context.user.name_in_tutorials);
    }
    else {
      cy.wrap($el).should("not.contain", context.user.name_in_tutorials);
    }
  });
}

function loginAsTeacherAndVisitLectureEdit(context) {
  cy.logout();
  cy.login(context.teacher);
  cy.visit(`/lectures/${context.lecture.id}/edit`);
  cy.getBySelector("people-tab-btn").click();
}

function runTutorialTest(tutorialCount) {
  it(`allows the user to successfully submit ${tutorialCount} tutorial(s) and become their tutor`, function () {
    createTutorials(this);

    let tutorialIds;

    cy.then(() => {
      switch (tutorialCount) {
        case 1:
          tutorialIds = [this.tutorial1.id];
          break;
        case 2:
          tutorialIds = [this.tutorial1.id, this.tutorial2.id];
          break;
        case 3:
          tutorialIds = [this.tutorial1.id, this.tutorial2.id, this.tutorial3.id];
          break;
        default:
          throw new Error("Invalid tutorial count");
      }
      submitVoucher(this.voucher);
      selectTutorialsAndSubmit(tutorialIds);
    });

    cy.then(() => {
      loginAsTeacherAndVisitLectureEdit(this);
    });

    cy.then(() => {
      verifyTutorialRowsContainTutorName(this, tutorialIds);
    });
  });
}

describe("Profile page", () => {
  beforeEach(function () {
    createRedemptionScenario(this);
  });

  it("shows redeem voucher card and verify voucher form", function () {
    cy.getBySelector("redeem-voucher-card").should("contain", this.redeem_voucher);
    cy.getBySelector("verify-voucher-form").should("be.visible");
  });

  describe("Tutor voucher redemption", () => {
    describe("if the lecture has no tutorials yet", () => {
      it("allows redemption of voucher to successfully become tutor", function () {
        submitVoucher(this.voucher);
        verifyVoucherRedemptionText();
        verifyNoTutorialsYetMessage(this);

        cy.then(() => {
          redeemVoucherToBecomeTutor(this);
        });

        cy.then(() => {
          loginAsTeacherAndVisitLectureEdit(this);
        });

        cy.then(() => {
          cy.getBySelector("tutorial-row").should("not.exist");
          cy.getBySelector("new-tutorial-btn").should("be.visible").click();
        });

        cy.then(() => {
          cy.getBySelector("tutorial-form").should("be.visible");
          cy.getBySelector("tutor-select").should("be.visible").within(() => {
            cy.get("option").should("contain", this.user.name_in_tutorials)
              .and("contain", this.user.email)
              .and("not.contain", this.user.name);
          });
        });
      });
    });

    describe("if the lecture has tutorials", () => {
      runTutorialTest(1);
      runTutorialTest(2);
      runTutorialTest(3);
    });

    describe("if the lecture has tutorials and the user is already a tutor for all of them", () => {
      it("displays a message that the user is already a tutor for all tutorials", function () {
        createTutorialsWithTutor(this, this.user);

        cy.then(() => {
          submitVoucher(this.voucher);
        });
      });
    });
  });
});
