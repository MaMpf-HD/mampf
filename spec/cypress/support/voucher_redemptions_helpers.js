import FactoryBot from "./factorybot";

export function createRedemptionScenario(context, role = "tutor", sort = "lecture") {
  cy.createUser("teacher").as("teacher");
  cy.createUserAndLogin("generic").as("user");

  cy.then(() => {
    FactoryBot.create("lecture",
      { teacher_id: context.teacher.id, sort: sort },
      { instance_methods: ["title_no_term", "title_for_viewers"] }).as("lecture");
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

export function verifyVoucherRedemptionText() {
  cy.getBySelector("redeem-voucher-text").should("be.visible");
}

export function verifyNoItemsYetMessage(context, itemType) {
  cy.i18n(`profile.no_${itemType}s_yet`).as("noItemsYet");

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

// Verifies that the tutorials or talks that were claimed are
// displayed in the lecture edit page and contain the user's name
// (and all the other ones do not)
// If totalCount is specified, it is used to check the total number of
// tutorials or talks in the lecture.
export function verifyClaimsContainUserName(context, claimType, claimIds, totalCount = 3) {
  let claimSelector = claimType === "tutorial" ? "tutorial-row" : "talk-header";
  cy.getBySelector(claimSelector).should("have.length", totalCount).each(($el) => {
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
  cy.logout();
  cy.login(context.teacher);
}

export function verifyNoTutorialsButUserEligibleAsTutor(context) {
  cy.getBySelector("tutorial-row").should("not.exist");
  cy.getBySelector("new-tutorial-btn").should("be.visible").click();
  cy.then(() => {
    cy.getBySelector("tutorial-form").should("be.visible");
    cy.getBySelector("tutor-select").within(() => {
      cy.get("option").should("contain", context.user.name_in_tutorials)
        .and("contain", context.user.email)
        .and("not.contain", context.user.name);
    });
  });
}

export function verifyLectureIsSubscribed(context) {
  cy.visit("/main/start");
  cy.getBySelector("subscribed-inactive-lectures-collapse")
    .should("contain", context.lecture.title_no_term);
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
    cy.getBySelector("notification-header")
      .should("contain", context.lecture.title_for_viewers);
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
  cy.i18n("profile.already_teacher").as("alreadyTeacher");

  cy.then(() => {
    cy.getBySelector("redeem-voucher-card")
      .should("contain", context.alreadyTeacher);
  });
}

export function visitEditPage(context, type) {
  if (type === "talk") {
    cy.visit(`/lectures/${context.lecture.id}/edit`);
  }
  else {
    cy.visit(`/lectures/${context.lecture.id}/edit`);
    cy.getBySelector("people-tab-btn").click();
  }
}

export function verifyNoTalksYetButUserEligibleAsSpeaker(context) {
  cy.i18n("admin.lecture.no_talks").as("noTalksYet");

  cy.then(() => {
    cy.getBySelector("no-talks-yet").should("contain", context.noTalksYet);
    cy.getBySelector("new-talk-btn").should("be.visible");
    cy.getBySelector("new-talk-btn").click();
  });

  cy.then(() => {
    cy.getBySelector("talk-form").should("be.visible");
    cy.getBySelector("speaker-select").within(() => {
      cy.get("option").should("contain", context.user.name_in_tutorials)
        .and("contain", context.user.email)
        .and("not.contain", context.user.name);
    });
  });
}

export function verifyNoClaimsYetButUserEligibleForRole(context, role) {
  role === "tutor" ? verifyNoTutorialsButUserEligibleAsTutor(context) : verifyNoTalksYetButUserEligibleAsSpeaker(context);
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
