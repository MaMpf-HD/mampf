import FactoryBot from "../support/factorybot";

export function createRedemptionScenario(context, role = "tutor", sort = "lecture") {
  cy.createUser("teacher").as("teacher");
  cy.createUserAndLogin("generic").as("user");

  cy.then(() => {
    FactoryBot.create("lecture",
      { teacher_id: context.teacher.id, sort: sort }).as("lecture");
  });

  cy.then(() => {
    FactoryBot.create("voucher", { lecture_id: context.lecture.id, role: role })
      .as("voucher");
  });

  cy.then(() => {
    cy.visit("/profile/edit");
  });

  cy.i18n("profile.redeem_voucher").as("redeem_voucher");
}

export function submitVoucher(voucher) {
  cy.getBySelector("secure-hash-input").type(voucher.secure_hash);
  cy.getBySelector("verify-voucher-submit").click();
}

export function verifyVoucherInvalidAlert(context, hash) {
  expect(hash).to.not.be.empty;
  cy.getBySelector("secure-hash-input").type(hash);
  cy.i18n("controllers.voucher_invalid").then((voucherInvalidMsg) => {
    cy.on("window:alert", (message) => {
      expect(message).to.equal(voucherInvalidMsg);
    });
    cy.getBySelector("verify-voucher-submit").click();
  });
}

export function verifyVoucherRedemptionText() {
  cy.getBySelector("redeem-voucher-text").should("be.visible");
}

export function verifyNoItemsYetMessage(context, itemType) {
  cy.i18n(`profile.no_${itemType}s_redemption`).as("noItemsYet");

  cy.then(() => {
    cy.getBySelector("redeem-voucher-card").should("contain", context.noItemsYet);
    cy.getBySelector("redeem-voucher-btn").should("be.visible");
  });
}

export function verifyAlreadyRedeemedVoucherMessage(context, role) {
  cy.i18n(`profile.already_${role}_by_redemption`).as("alreadyRedeemedVoucher");

  cy.then(() => {
    cy.getBySelector("redeem-voucher-card")
      .should("contain", context.alreadyRedeemedVoucher);
  });
}

export function redeemVoucherToBecomeRole(context, role) {
  cy.i18n(`controllers.become_${role}_success`).as("successMessage");
  cy.getBySelector("redeem-voucher-btn").click();

  cy.then(() => {
    cy.getBySelector("flash-notice").should("be.visible")
      .and("contain", context.successMessage);
  });
}

// Creates tutorials or talks, number is specified by count parameter.
// If user is given as parameter, the user is assigned as tutor or speaker.
export function createTutorialsOrTalks(context, entityType, user = null, count = 3) {
  const entityData = { lecture_id: context.lecture.id };
  if (user) {
    const personKey = entityType === "tutorial" ? "tutor_ids" : "speaker_ids";
    entityData[personKey] = [user.id];
  }

  for (let i = 1; i <= count; i++) {
    FactoryBot.create(entityType, entityData).as(`${entityType}${i}`);
  }
}

export function selectClaimsAndSubmit(entityIds) {
  const entityIdsAsStrings = entityIds.map(id => id.toString());

  cy.getBySelector("claim-select").should("be.visible");
  cy.getBySelector("claim-select").select(entityIdsAsStrings, { force: true });
  cy.getBySelector("claim-submit").click();
  cy.getBySelector("flash-notice").should("be.visible");
}

// Verifies that the talks that were claimed are displayed in the
// lecture edit page and contain the user's name
// (and all the other ones do not)
// If totalCount is specified, it is used to check the total number of
// talks in the lecture.
export function verifyClaimsContainUserName(context, claimIds, totalCount = 3) {
  cy.getBySelector("talk-header").should("have.length", totalCount).each(($el) => {
    const dataId = parseInt($el.attr("data-id"), 10);
    if (claimIds.includes(dataId)) {
      cy.wrap($el).should("contain", context.user.name_in_tutorials);
    }
    else {
      cy.wrap($el).should("not.contain", context.user.name_in_tutorials);
    }
  });
}

export function logoutAndLoginAsTeacher(context) {
  cy.logout().then(() => {
    cy.login(context.teacher);
  });
}

export function verifyLectureIsSubscribed(context) {
  cy.visit("/main/start");
  context.lecture.call.title_no_term().then((title) => {
    cy.getBySelector("subscribed-inactive-lectures-collapse").should("contain", title);
  });
}

export function verifyRoleNotification(context, role) {
  cy.i18n(`basics.${role}`).as("roleMessage");
  cy.i18n("notifications.redemption").as("redemptionMessage");

  cy.then(() => {
    cy.visit("/main/start");
    cy.getBySelector("notification-dropdown").should("be.visible");
    cy.getBySelector("notification-dropdown-counter").should("contain", "1");
    cy.getBySelector("notification-dropdown-menu")
      .should("contain", context.roleMessage)
      .and("contain", context.user.name_in_tutorials);
    cy.visit("/notifications");
    cy.getBySelector("notification-card").should("have.length", 1);
    context.lecture.call.title_for_viewers().then((title) => {
      cy.getBySelector("notification-header").should("contain", title);
    });
    cy.getBySelector("notification-body")
      .should("contain", context.redemptionMessage)
      .and("contain", context.user.name_in_tutorials)
      .and("contain", context.user.email);
  });
}

export function verifyAllItemsTakenMessage(context, itemType) {
  cy.i18n(`profile.all_${itemType}s_taken`).as("allItemsTaken");

  cy.then(() => {
    cy.getBySelector("redeem-voucher-card")
      .should("contain", context.allItemsTaken);
  });
}

export function verifyCancelVoucherButton() {
  cy.getBySelector("cancel-voucher-btn").should("be.visible");
  cy.getBySelector("cancel-voucher-btn").click();
  cy.then(() => {
    cy.getBySelector("verify-voucher-form").should("be.visible");
  });
}

export function verifyNoNotification() {
  cy.visit("/main/start");
  cy.getBySelector("notification-dropdown").should("not.exist");
}

export function verifyNoNewNotification() {
  cy.visit("/main/start");
  cy.getBySelector("notification-dropdown").should("be.visible");
  cy.getBySelector("notification-dropdown-counter").should("contain", "1");
}

export function verifyTeachersCantBecomeEditorsMessage(context) {
  cy.i18n("profile.teacher_cant_become_editor").as("teacherCantBecomeEditor");

  cy.then(() => {
    cy.getBySelector("redeem-voucher-card")
      .should("contain", context.teacherCantBecomeEditor);
  });
}

export function verifyUserIsTeacher(context) {
  cy.getBySelector("teacher-info")
    .should("contain", context.user.name_in_tutorials)
    .and("contain", context.user.email)
    .and("not.contain", context.user.name);
};

export function verifyPreviousTeacherIsEditor(context) {
  cy.getBySelector("lecture-editors-select").within(() => {
    cy.get("option").should("contain", context.teacher.name_in_tutorials)
      .and("contain", context.teacher.email)
      .and("not.contain", context.teacher.name);
  });
}

export function verifyAlreadyTeacherMessage(context) {
  context.lecture.call.title().then((lectureTitle) => {
    cy.i18n("profile.already_teacher_html", { lecture: lectureTitle }).as("alreadyTeacher");
  });

  cy.then(() => {
    cy.getBySelector("redeem-voucher-card")
      .should("contain.html", context.alreadyTeacher);
  });
}

export function visitEditPage(context, type) {
  let url = `/lectures/${context.lecture.id}/edit`;
  if (type !== "talk") {
    url += "?tab=people";
  }
  cy.visit(url);
  return cy.getBySelector("lecture-area").should("be.visible");
}

export function verifyNoTalksYet(context) {
  cy.i18n("admin.lecture.no_talks").as("noTalksYet");

  cy.then(() => {
    cy.getBySelector("no-talks-yet").should("contain", context.noTalksYet);
  });
}

export function verifyUserIsEditor(context) {
  cy.getBySelector("lecture-editors-select").within(() => {
    cy.get("option").should("contain", context.user.name_in_tutorials)
      .and("contain", context.user.email)
      .and("not.contain", context.user.name);
  });
}

export function verifyNothingClaimedInNotification(context, claimType) {
  cy.i18n(`notifications.no_${claimType}s_taken`).as("nothingClaimed");

  cy.then(() => {
    cy.getBySelector("notification-body")
      .should("contain", context.nothingClaimed);
  });
}
