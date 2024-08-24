import FactoryBot from "../support/factorybot";

function createRedemptionScenario(context) {
  cy.createUserAndLogin("generic").as("user");

  cy.then(() => {
    FactoryBot.create("lecture").as("lecture");
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

function verifyVoucherRedemption() {
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

describe("Profile page", () => {
  beforeEach(function () {
    createRedemptionScenario(this);
  });

  it("shows redeem voucher card and verify voucher form", function () {
    cy.getBySelector("redeem-voucher-card").should("contain", this.redeem_voucher);
    cy.getBySelector("verify-voucher-form").should("be.visible");
  });

  describe("Verify voucher form", () => {
    describe("for tutor vouchers", () => {
      it("can submit a valid voucher", function () {
        submitVoucher(this.voucher);
        verifyVoucherRedemption();
      });
    });
  });

  describe("Tutor voucher redemption", () => {
    describe("if the lecture has no tutorials yet", () => {
      it("shows a message that there are no tutorials and a redeem voucher button", function () {
        submitVoucher(this.voucher);
        verifyNoTutorialsYetMessage(this);
      });

      it("allows redemption of voucher to become tutor", function () {
        submitVoucher(this.voucher);
        cy.then(() => {
          redeemVoucherToBecomeTutor(this);
        });
      });
    });

    describe("if the lecture has tutorials", () => {
      it("shows a message after submission that there are tutorials and a select form",
        function () {
          FactoryBot.create("tutorial", { lecture_id: this.lecture.id })
            .as("tutorial1");
          FactoryBot.create("tutorial", { lecture_id: this.lecture.id })
            .as("tutorial2");

          cy.then(() => {
            submitVoucher(this.voucher);
            cy.getBySelector("claim-select").should("be.visible");
            cy.getBySelector("claim-select").tomselect([this.tutorial1.id, this.tutorial2.id]);
            cy.getBySelector("claim-submit").click();
            cy.then(() => {
              cy.getBySelector("flash-notice").should("be.visible");
            });
          });
        });
    });
  });
});
