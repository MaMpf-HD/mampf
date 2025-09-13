import * as helpers from "./vouchers_redemptions_spec_helpers";

function testVoucherRedemptionWithNothingToClaim(context, role, itemType) {
  helpers.submitVoucher(context.voucher);
  helpers.verifyVoucherRedemptionText();
  helpers.verifyNoItemsYetMessage(context, itemType);
  helpers.redeemVoucherToBecomeRole(context, role);
  helpers.verifyLectureIsSubscribed(context);
  helpers.logoutAndLoginAsTeacher(context);

  cy.then(() => {
    helpers.visitEditPage(context, itemType);
    helpers.verifyNoClaimsYetButUserEligibleForRole(context, role);
    helpers.verifyRoleNotification(context, role);
    helpers.verifyNothingClaimedInNotification(context, itemType);
  });
}

function testVoucherRedemptionWithSomethingClaimed(context, itemType, role) {
  helpers.createTutorialsOrTalks(context, itemType);

  const itemIds = [];
  const itemTitles = [];

  cy.then(() => {
    itemIds.push(context[`${itemType}1`].id, context[`${itemType}2`].id);
    itemTitles.push(context[`${itemType}1`].title, context[`${itemType}2`].title);
  });

  cy.then(() => {
    helpers.submitVoucher(context.voucher);
    helpers.selectClaimsAndSubmit(itemIds);
  });

  helpers.verifyLectureIsSubscribed(context);
  helpers.logoutAndLoginAsTeacher(context);

  cy.then(() => {
    helpers.visitEditPage(context, itemType);
    helpers.verifyClaimsContainUserName(context, itemType, itemIds);
  });

  cy.then(() => {
    helpers.verifyRoleNotification(context, role);
    cy.getBySelector("notification-body").should("contain", itemTitles[0])
      .and("contain", itemTitles[1]);
  });
}

function testAlreadyRedeemedVoucher(context, role) {
  helpers.submitVoucher(context.voucher);
  helpers.redeemVoucherToBecomeRole(context, role);
  helpers.submitVoucher(context.voucher);
  helpers.verifyAlreadyRedeemedVoucherMessage(context, role);
  helpers.verifyCancelVoucherButton();
  helpers.logoutAndLoginAsTeacher(context);
  cy.then(() => {
    helpers.verifyNoNewNotification();
  });
}

function testAlreadyRoleForAllItems(context, itemType) {
  helpers.createTutorialsOrTalks(context, itemType, context.user);
  helpers.submitVoucher(context.voucher);
  helpers.verifyAllItemsTakenMessage(context, itemType);
  helpers.verifyCancelVoucherButton();
  helpers.logoutAndLoginAsTeacher(context);
  cy.then(() => {
    helpers.verifyNoNotification();
  });
}

describe("Verify Voucher Form", () => {
  beforeEach(function () {
    helpers.createRedemptionScenario(this);
  });

  it("is shown on the profile page", function () {
    cy.getBySelector("redeem-voucher-card").should("contain", this.redeem_voucher);
    cy.getBySelector("verify-voucher-form").should("be.visible");
  });

  it("displays an alert if the voucher is invalid", function () {
    helpers.verifyVoucherInvalidAlert(this, "incorrect hash");
  });

  it("is valid even if voucher string contains whitespaces at the beginning/end", function () {
    cy.getBySelector("secure-hash-input").type(`\t  ${this.voucher.secure_hash} `);
    cy.getBySelector("verify-voucher-submit").click();
    helpers.verifyVoucherRedemptionText();
  });
});

describe("Tutor voucher redemption", () => {
  beforeEach(function () {
    helpers.createRedemptionScenario(this, "tutor");
  });

  context("when the lecture has no tutorials yet", () => {
    it("allows redemption of voucher to successfully become tutor", function () {
      testVoucherRedemptionWithNothingToClaim(this, "tutor", "tutorial");
    });

    context("and the user has already redeemed the voucher", () => {
      it("displays a message that the user has already redeemed the voucher", function () {
        testAlreadyRedeemedVoucher(this, "tutor");
      });
    });
  });

  context("when the lecture has tutorials", () => {
    it("allows the user to successfully submit tutorials and become their tutor", function () {
      testVoucherRedemptionWithSomethingClaimed(this, "tutorial", "tutor");
    });

    context("and the user is already a tutor for all of them", () => {
      it("displays a message that the user is already a tutor for all tutorials", function () {
        testAlreadyRoleForAllItems(this, "tutorial");
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
    helpers.visitEditPage(this, "editor");
    helpers.verifyUserIsEditor(this);
    helpers.verifyRoleNotification(this, "editor");
  });

  context("when the user has already redeemed the voucher", () => {
    it("displays a message that the user has already redeemed the voucher", function () {
      helpers.submitVoucher(this.voucher);
      helpers.redeemVoucherToBecomeRole(this, "editor");
      helpers.submitVoucher(this.voucher);
      helpers.verifyAlreadyRedeemedVoucherMessage(this, "editor");
      helpers.verifyCancelVoucherButton();
      helpers.logoutAndLoginAsTeacher(this);
      cy.then(() => {
        helpers.verifyNoNewNotification();
      });
    });
  });

  context("when the user is the teacher of the lecture", () => {
    it("displays the message that a teacher cannot become an editor", function () {
      helpers.logoutAndLoginAsTeacher(this);

      cy.then(() => {
        helpers.submitVoucher(this.voucher);
        helpers.verifyTeachersCantBecomeEditorsMessage(this);
        helpers.verifyCancelVoucherButton();
      });
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
    helpers.visitEditPage(this, "teacher");
    helpers.verifyUserIsTeacher(this);
    helpers.verifyPreviousTeacherIsEditor(this);
    helpers.verifyRoleNotification(this, "teacher");
    cy.visit("/profile/edit");
    helpers.verifyVoucherInvalidAlert(this, this.voucher.secure_hash);
  });

  context("when the user is already the teacher", () => {
    it("displays a message that the user is already the teacher", function () {
      helpers.logoutAndLoginAsTeacher(this);

      cy.then(() => {
        helpers.submitVoucher(this.voucher);
        helpers.verifyAlreadyTeacherMessage(this);
        helpers.verifyCancelVoucherButton();
      });
    });
  });
});

describe("Speaker voucher redemption", () => {
  beforeEach(function () {
    helpers.createRedemptionScenario(this, "speaker", "seminar");
  });

  context("when the seminar has no talks yet", () => {
    it("allows the user to successfully become a speaker", function () {
      testVoucherRedemptionWithNothingToClaim(this, "speaker", "talk");
    });

    context("and the user has already redeemed the voucher", () => {
      it("displays a message that the user has already redeemed the voucher", function () {
        testAlreadyRedeemedVoucher(this, "speaker");
      });
    });
  });

  context("when the seminar has talks", () => {
    it("allows the user to successfully submit talks and become their speaker", function () {
      testVoucherRedemptionWithSomethingClaimed(this, "talk", "speaker");
    });

    context("and the user is already a speaker for all of them", () => {
      it("displays a message that the user is already a speaker for all talks ", function () {
        testAlreadyRoleForAllItems(this, "talk");
      });
    });
  });
});

describe("User & Redemption deletion", () => {
  beforeEach(function () {
    helpers.createRedemptionScenario(this, "tutor");
  });

  it("after deletion of tutor user, it is no longer selectable", function () {
    helpers.submitVoucher(this.voucher);
    helpers.redeemVoucherToBecomeRole(this, "tutor");

    cy.visit("/profile/edit");
    cy.getBySelector("delete-account-btn").click();
    cy.getBySelector("delete-account-pwd-field").type(this.user.password);

    cy.intercept("POST", "/users*").as("deleteUserRequest");
    cy.getBySelector("delete-account-confirm-btn").click();
    cy.wait("@deleteUserRequest");

    cy.then(() => {
      helpers.logoutAndLoginAsTeacher(this);
    });

    cy.then(() => {
      helpers.visitEditPage(this, "tutorial").then(() => {
        helpers.verifyNoTutorialsButUserEligibleAsTutor(this, false);
      });
    });
  });
});
