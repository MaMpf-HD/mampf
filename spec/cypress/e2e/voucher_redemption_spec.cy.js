import * as helpers from "../support/voucher_redemption_helpers";

describe("Verify Voucher Form", () => {
  beforeEach(function () {
    helpers.createRedemptionScenario(this);
  });

  it("is shown on the profile page", function () {
    cy.getBySelector("redeem-voucher-card").should("contain", this.redeem_voucher);
    cy.getBySelector("verify-voucher-form").should("be.visible");
  });

  it("displays an alert if the voucher is invalid", function () {
    cy.getBySelector("secure-hash-input").type("incorrect hash");
    cy.i18n("controllers.voucher_invalid").as("voucherInvalid");

    cy.then(() => {
      cy.getBySelector("verify-voucher-submit").click();
    });

    cy.on("window:alert", (message) => {
      expect(message).to.equal(this.voucherInvalid);
    });
  });
});

describe("Tutor voucher redemption", () => {
  beforeEach(function () {
    helpers.createRedemptionScenario(this, "tutor");
  });

  describe("if the lecture has no tutorials yet", () => {
    it("allows redemption of voucher to successfully become tutor", function () {
      helpers.submitVoucher(this.voucher);
      helpers.verifyVoucherRedemptionText();
      helpers.verifyNoItemsYetMessage(this, "tutorial");
      helpers.redeemVoucherToBecomeRole(this, "tutor");
      helpers.verifyLectureIsSubscribed(this);
      helpers.logoutAndLoginAsTeacher(this);
      helpers.visitLectureEdit(this);
      helpers.verifyNoTutorialsButUserEligibleAsTutor(this);
      helpers.verifyRoleNotification(this, "tutor");
      helpers.verifyNothingClaimedInNotification(this, "tutorial");
    });

    describe("and the user has already redeemed the voucher", () => {
      it("displays a message that the user has already redeemed the voucher", function () {
        helpers.submitVoucher(this.voucher);
        helpers.redeemVoucherToBecomeRole(this, "tutor");
        // redeem the voucher again
        helpers.submitVoucher(this.voucher);
        helpers.verifyAlreadyRedeemedVoucherMessage(this, "tutor");
        helpers.verifyCancelVoucherButton();
        helpers.logoutAndLoginAsTeacher(this);
        helpers.verifyNoNewNotification();
      });
    });
  });

  describe("if the lecture has tutorials", () => {
    it("allows the user to successfully submit tutorials and become their tutor", function () {
      const tutorialIds = [];

      helpers.createTutorialsOrTalks(this, "tutorial");

      cy.then(() => {
        tutorialIds.push(this.tutorial1.id, this.tutorial2.id);
      });

      cy.then(() => {
        helpers.submitVoucher(this.voucher);
        helpers.selectClaimsAndSubmit(tutorialIds);
      });

      helpers.verifyLectureIsSubscribed(this);
      helpers.logoutAndLoginAsTeacher(this);
      helpers.visitLectureEdit(this);

      cy.then(() => {
        helpers.verifyClaimsContainUserName(this, "tutorial", tutorialIds);
      });

      cy.then(() => {
        helpers.verifyRoleNotification(this, "tutor");
        cy.getBySelector("notification-body").should("contain", this.tutorial1.title)
          .and("contain", this.tutorial2.title);
      });
    });

    describe("and the user is already a tutor for all of them", () => {
      it("displays a message that the user is already a tutor for all tutorials", function () {
        helpers.createTutorialsOrTalks(this, "tutorial", this.user);
        helpers.submitVoucher(this.voucher);
        helpers.verifyAllItemsTakenMessage(this, "tutorial");
        helpers.verifyCancelVoucherButton();
        helpers.logoutAndLoginAsTeacher(this);
        helpers.verifyNoNotification();
      });
    });
  });
});

describe("Editor voucher redemption", () => {
  beforeEach(function () {
    helpers.createRedemptionScenario(this, "editor");
  });

  it("allows the user to successfully become an editor", function () {
    helpers.submitVoucher(this.voucher);
    helpers.verifyVoucherRedemptionText();
    helpers.redeemVoucherToBecomeRole(this, "editor");
    helpers.verifyLectureIsSubscribed(this);
    helpers.visitLectureEdit(this);
    helpers.verifyUserIsEditor(this);
    helpers.verifyRoleNotification(this, "editor");
  });

  describe("if the user has already redeemed the voucher", () => {
    it("displays a message that the user has already redeemed the voucher", function () {
      helpers.submitVoucher(this.voucher);
      helpers.redeemVoucherToBecomeRole(this, "editor");
      helpers.submitVoucher(this.voucher);
      helpers.verifyAlreadyRedeemedVoucherMessage(this, "editor");
      helpers.verifyCancelVoucherButton();
      helpers.logoutAndLoginAsTeacher(this);
      helpers.verifyNoNewNotification();
    });
  });

  describe("if the user is the teacher of the lecture", () => {
    it("displays the message that a teacher cannot become an editor", function () {
      helpers.logoutAndLoginAsTeacher(this);
      helpers.submitVoucher(this.voucher);
      helpers.verifyTeachersCantBecomeEditorsMessage(this);
      helpers.verifyCancelVoucherButton();
    });
  });
});

describe("Teacher voucher redemption", () => {
  beforeEach(function () {
    helpers.createRedemptionScenario(this, "teacher");
  });

  it("allows the user to successfully become a teacher", function () {
    helpers.submitVoucher(this.voucher);
    helpers.verifyVoucherRedemptionText();
    helpers.redeemVoucherToBecomeRole(this, "teacher");
    helpers.verifyLectureIsSubscribed(this);
    helpers.visitLectureEdit(this);
    helpers.verifyUserIsTeacher(this);
    helpers.verifyPreviousTeacherIsEditor(this);
    helpers.verifyRoleNotification(this, "teacher");
  });

  describe("if the user is already the teacher", () => {
    it("displays a message that the user is already the teacher", function () {
      helpers.logoutAndLoginAsTeacher(this);
      helpers.submitVoucher(this.voucher);
      helpers.verifyAlreadyTeacherMessage(this);
      helpers.verifyCancelVoucherButton();
    });
  });
});

describe("Speaker voucher redemption", () => {
  beforeEach(function () {
    helpers.createRedemptionScenario(this, "speaker", "seminar");
  });

  describe("If the seminar has no talks yet", () => {
    it("allows the user to successfully become a speaker", function () {
      helpers.submitVoucher(this.voucher);
      helpers.verifyVoucherRedemptionText();
      helpers.verifyNoItemsYetMessage(this, "talk");
      helpers.redeemVoucherToBecomeRole(this, "speaker");
      helpers.verifyLectureIsSubscribed(this);
      helpers.logoutAndLoginAsTeacher(this);
      helpers.visitLectureContentEdit(this);
      helpers.verifyNoTalksYetButUserEligibleAsSpeaker(this);
      helpers.verifyRoleNotification(this, "speaker");
      helpers.verifyNothingClaimedInNotification(this, "talk");
    });

    describe("and the user has already redeemed the voucher", () => {
      it("displays a message that the user has already redeemed the voucher", function () {
        helpers.submitVoucher(this.voucher);
        helpers.redeemVoucherToBecomeRole(this, "speaker");
        // redeem the voucher again
        helpers.submitVoucher(this.voucher);
        helpers.verifyAlreadyRedeemedVoucherMessage(this, "speaker");
        helpers.verifyCancelVoucherButton();
        helpers.logoutAndLoginAsTeacher(this);
        helpers.verifyNoNewNotification();
      });
    });
  });

  describe("if the seminar has talks", () => {
    it("allows the user to successfully submit talks and become their speaker", function () {
      const talkIds = [];

      helpers.createTutorialsOrTalks(this, "talk");

      cy.then(() => {
        talkIds.push(this.talk1.id, this.talk2.id);
      });

      cy.then(() => {
        helpers.submitVoucher(this.voucher);
        helpers.selectClaimsAndSubmit(talkIds);
      });

      helpers.verifyLectureIsSubscribed(this);
      helpers.logoutAndLoginAsTeacher(this);
      helpers.visitLectureContentEdit(this);

      cy.then(() => {
        helpers.verifyClaimsContainUserName(this, "talk", talkIds);
      });

      cy.then(() => {
        helpers.verifyRoleNotification(this, "speaker");
        cy.getBySelector("notification-body").should("contain", this.talk1.title)
          .and("contain", this.talk2.title);
      });
    });

    describe("and the user is already a speaker for all of them", () => {
      it("displays a message that the user is already a speaker for all talks", function () {
        helpers.createTutorialsOrTalks(this, "talk", this.user);
        helpers.submitVoucher(this.voucher);
        helpers.verifyAllItemsTakenMessage(this, "talk");
        helpers.verifyCancelVoucherButton();
        helpers.logoutAndLoginAsTeacher(this);
        helpers.verifyNoNotification();
      });
    });
  });
});
