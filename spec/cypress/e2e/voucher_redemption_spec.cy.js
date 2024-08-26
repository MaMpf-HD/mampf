import FactoryBot from "../support/factorybot";

function createRedemptionScenario(context, role = "tutor", sort = "lecture") {
  cy.createUser("teacher").as("teacher");
  cy.createUserAndLogin("generic").as("user");

  cy.then(() => {
    FactoryBot.create("lecture",
      { teacher_id: context.teacher.id, sort: sort },
      { instance_methods: ["title_no_term", "title_for_viewers"] }).as("lecture");
  });

  cy.then(() => {
    FactoryBot.create("voucher", { lecture_id: context.lecture.id, role: role }).as("voucher");
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

function verifyNoItemsYetMessage(context, itemType) {
  cy.i18n(`profile.no_${itemType}s_yet`).as("noItemsYet");

  cy.then(() => {
    cy.getBySelector("redeem-voucher-card").should("contain", context.noItemsYet);
    cy.getBySelector("redeem-voucher-btn").should("be.visible");
  });
}

function verifyAlreadyRedeemedVoucherMessage(context, role) {
  cy.i18n(`profile.already_${role}_by_redemption`).as("alreadyRedeemedVoucher");

  cy.then(() => {
    cy.getBySelector("redeem-voucher-card")
      .should("contain", context.alreadyRedeemedVoucher);
  });
}

function redeemVoucherToBecomeRole(context, role) {
  cy.i18n(`controllers.become_${role}_success`).as("successMessage");
  cy.getBySelector("redeem-voucher-btn").click();

  cy.then(() => {
    cy.getBySelector("flash-notice").should("be.visible")
      .and("contain", context.successMessage);
  });
}

// Creates tutorials or talks, number is specified by count parameter.
// If user is given as parameter, the user is assigned as tutor or speaker.
function createTutorialsOrTalks(context, entityType, user = null, count = 3) {
  const entityData = { lecture_id: context.lecture.id };
  if (user) {
    const personKey = entityType === "tutorial" ? "tutor_ids" : "speaker_ids";
    entityData[personKey] = [user.id];
  }

  for (let i = 1; i <= count; i++) {
    FactoryBot.create(entityType, entityData).as(`${entityType}${i}`);
  }
}

function selectClaimsAndSubmit(entityIds) {
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
function verifyClaimsContainUserName(context, claimType, claimIds, totalCount = 3) {
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

function loginAsTeacher(context) {
  cy.logout();
  cy.login(context.teacher);
}

function visitLectureEdit(context) {
  cy.visit(`/lectures/${context.lecture.id}/edit`);
  cy.getBySelector("people-tab-btn").click();
}

function verifyNoTutorialsButUserEligibleAsTutor(context) {
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

function verifyLectureIsSubscribed(context) {
  cy.visit("/main/start");
  cy.getBySelector("subscribed-inactive-lectures-collapse").should("contain", context.lecture.title_no_term);
}

function verifyRoleNotification(context, role) {
  cy.i18n(`basics.${role}`).as("roleMessage");
  cy.i18n("notifications.redemption").as("redemptionMessage");

  cy.then(() => {
    cy.visit("/main/start");
    cy.getBySelector("notification-dropdown").should("be.visible");
    cy.getBySelector("notification-dropdown-counter").should("contain", "1");
    cy.getBySelector("notification-dropdown-menu").should("contain", context.roleMessage)
      .and("contain", context.user.name_in_tutorials);
    cy.visit("/notifications");
    cy.getBySelector("notification-card").should("have.length", 1);
    cy.getBySelector("notification-header").should("contain", context.lecture.title_for_viewers);
    cy.getBySelector("notification-body").should("contain", context.redemptionMessage)
      .and("contain", context.user.name_in_tutorials).and("contain", context.user.email);
  });
}

function verifyAllItemsTakenMessage(context, itemType) {
  cy.i18n(`profile.all_${itemType}s_taken`).as("allItemsTaken");

  cy.then(() => {
    cy.getBySelector("redeem-voucher-card").should("contain", context.allItemsTaken);
  });
}

function verifyCancelVoucherButton() {
  cy.getBySelector("cancel-voucher-btn").should("be.visible");
  cy.getBySelector("cancel-voucher-btn").click();
  cy.then(() => {
    cy.getBySelector("verify-voucher-form").should("be.visible");
  });
}

function verifyNoNotification() {
  cy.visit("/main/start");
  cy.getBySelector("notification-dropdown").should("not.exist");
}

function verifyNoNewNotification() {
  cy.visit("/main/start");
  cy.getBySelector("notification-dropdown").should("be.visible");
  cy.getBySelector("notification-dropdown-counter").should("contain", "1");
}

function verifyTeachersCantBecomeEditorsMessage(context) {
  cy.i18n("profile.teacher_cant_become_editor").as("teacherCantBecomeEditor");

  cy.then(() => {
    cy.getBySelector("redeem-voucher-card").should("contain", context.teacherCantBecomeEditor);
  });
}

function verifyUserIsTeacher(context) {
  cy.getBySelector("teacher-info").should("contain", context.user.name_in_tutorials)
    .and("contain", context.user.email)
    .and("not.contain", context.user.name);
};

function verifyPreviousTeacherIsEditor(context) {
  cy.getBySelector("lecture-editors-select").within(() => {
    cy.get("option").should("contain", context.teacher.name_in_tutorials)
      .and("contain", context.teacher.email)
      .and("not.contain", context.teacher.name);
  });
}

function verifyAlreadyTeacherMessage(context) {
  cy.i18n("profile.already_teacher").as("alreadyTeacher");

  cy.then(() => {
    cy.getBySelector("redeem-voucher-card").should("contain", context.alreadyTeacher);
  });
}

function visitLectureContentEdit(context) {
  cy.visit(`/lectures/${context.lecture.id}/edit`);
}

function verifyNoTalksYetButUserEligibleAsSpeaker(context) {
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

describe("Verify Voucher Form", () => {
  beforeEach(function () {
    createRedemptionScenario(this);
  });

  it("is shown on the profile page", function () {
    cy.then(() => {
      cy.getBySelector("redeem-voucher-card").should("contain", this.redeem_voucher);
      cy.getBySelector("verify-voucher-form").should("be.visible");
    });
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
    createRedemptionScenario(this, "tutor");
  });

  describe("if the lecture has no tutorials yet", () => {
    it("allows redemption of voucher to successfully become tutor", function () {
      cy.i18n("notifications.no_tutorials_taken").as("noTutorialsTaken");
      submitVoucher(this.voucher);
      verifyVoucherRedemptionText();
      verifyNoItemsYetMessage(this, "tutorial");

      cy.then(() => {
        redeemVoucherToBecomeRole(this, "tutor");
      });

      cy.then(() => {
        verifyLectureIsSubscribed(this);
      });

      cy.then(() => {
        loginAsTeacher(this);
        visitLectureEdit(this);
      });

      cy.then(() => {
        verifyNoTutorialsButUserEligibleAsTutor(this);
      });

      cy.then(() => {
        verifyRoleNotification(this, "tutor"); ;
        cy.i18n("notifications.no_tutorials_taken").as("noTutorialsTaken");
        cy.then(() => {
          cy.getBySelector("notification-body").should("contain", this.noTutorialsTaken);
        });
      });
    });

    describe("and the user has already redeemed the voucher", () => {
      it("displays a message that the user has already redeemed the voucher", function () {
        submitVoucher(this.voucher);
        redeemVoucherToBecomeRole(this, "tutor");

        // redeem the voucher again
        cy.then(() => {
          submitVoucher(this.voucher);
          verifyAlreadyRedeemedVoucherMessage(this, "tutor");
          verifyCancelVoucherButton();
        });

        loginAsTeacher(this);
        verifyNoNewNotification();
      });
    });
  });

  describe("if the lecture has tutorials", () => {
    it("allows the user to successfully submit tutorials and become their tutor", function () {
      let tutorialIds;

      createTutorialsOrTalks(this, "tutorial");

      cy.then(() => {
        tutorialIds = [this.tutorial1.id, this.tutorial2.id];
      });

      cy.then(() => {
        submitVoucher(this.voucher);
        selectClaimsAndSubmit(tutorialIds);
      });

      cy.then(() => {
        verifyLectureIsSubscribed(this);
      });

      cy.then(() => {
        loginAsTeacher(this);
        visitLectureEdit(this);
      });

      cy.then(() => {
        verifyClaimsContainUserName(this, "tutorial", tutorialIds);
      });

      cy.then(() => {
        verifyRoleNotification(this, "tutor"); ;
        cy.getBySelector("notification-body").should("contain", this.tutorial1.title)
          .and("contain", this.tutorial2.title);
      });
    });

    describe("and the user is already a tutor for all of them", () => {
      it("displays a message that the user is already a tutor for all tutorials", function () {
        createTutorialsOrTalks(this, "tutorial", this.user);

        cy.then(() => {
          submitVoucher(this.voucher);
        });

        cy.then(() => {
          verifyAllItemsTakenMessage(this, "tutorial");
          verifyCancelVoucherButton();
        });

        loginAsTeacher(this);
        verifyNoNotification();
      });
    });
  });
});

describe("Editor voucher redemption", () => {
  beforeEach(function () {
    createRedemptionScenario(this, "editor");
  });

  it("allows the user to successfully become an editor", function () {
    submitVoucher(this.voucher);
    verifyVoucherRedemptionText();
    redeemVoucherToBecomeRole(this, "editor");

    cy.then(() => {
      verifyLectureIsSubscribed(this);
    });

    cy.then(() => {
      visitLectureEdit(this);
    });

    cy.then(() => {
      cy.getBySelector("lecture-editors-select").within(() => {
        cy.get("option").should("contain", this.user.name_in_tutorials)
          .and("contain", this.user.email)
          .and("not.contain", this.user.name);
      });
    });

    cy.then(() => {
      verifyRoleNotification(this, "editor");
    });
  });

  describe("if the user has already redeemed the voucher", () => {
    it("displays a message that the user has already redeemed the voucher", function () {
      submitVoucher(this.voucher);
      redeemVoucherToBecomeRole(this, "editor");

      // redeem the voucher again
      cy.then(() => {
        submitVoucher(this.voucher);
        verifyAlreadyRedeemedVoucherMessage(this, "editor");
        verifyCancelVoucherButton();
      });

      loginAsTeacher(this);
      verifyNoNewNotification();
    });
  });

  describe("if the user is the teacher of the lecture", () => {
    it("displays the message that a teacher cannot become an editor", function () {
      loginAsTeacher(this);
      submitVoucher(this.voucher);

      cy.then(() => {
        verifyTeachersCantBecomeEditorsMessage(this);
        verifyCancelVoucherButton();
      });
    });
  });
});

describe("Teacher voucher redemption", () => {
  beforeEach(function () {
    createRedemptionScenario(this, "teacher");
  });

  it("allows the user to successfully become a teacher", function () {
    submitVoucher(this.voucher);
    verifyVoucherRedemptionText();
    redeemVoucherToBecomeRole(this, "teacher");

    verifyLectureIsSubscribed(this);
    visitLectureEdit(this);
    verifyUserIsTeacher(this);
    verifyPreviousTeacherIsEditor(this);

    verifyRoleNotification(this, "teacher");
  });

  describe("if the user is already the teacher", () => {
    it("displays a message that the user is already the teacher", function () {
      loginAsTeacher(this);
      submitVoucher(this.voucher);

      cy.then(() => {
        verifyAlreadyTeacherMessage(this);
        verifyCancelVoucherButton();
      });
    });
  });
});

describe("Speaker voucher redemption", () => {
  beforeEach(function () {
    createRedemptionScenario(this, "speaker", "seminar");
  });

  describe("If the seminar has no talks yet", () => {
    it("allows the user to successfully become a speaker", function () {
      submitVoucher(this.voucher);
      verifyVoucherRedemptionText();
      verifyNoItemsYetMessage(this, "talk");
      redeemVoucherToBecomeRole(this, "speaker");
      verifyLectureIsSubscribed(this);

      cy.then(() => {
        loginAsTeacher(this);
        visitLectureContentEdit(this);
      });

      cy.then(() => {
        verifyNoTalksYetButUserEligibleAsSpeaker(this);
      });

      cy.then(() => {
        verifyRoleNotification(this, "speaker"); ;
        cy.i18n("notifications.no_talks_taken").as("noTalksTaken");
        cy.then(() => {
          cy.getBySelector("notification-body").should("contain", this.noTalksTaken);
        });
      });
    });

    describe("and the user has already redeemed the voucher", () => {
      it("displays a message that the user has already redeemed the voucher", function () {
        submitVoucher(this.voucher);
        redeemVoucherToBecomeRole(this, "speaker");

        // redeem the voucher again
        cy.then(() => {
          submitVoucher(this.voucher);
          verifyAlreadyRedeemedVoucherMessage(this, "speaker");
          verifyCancelVoucherButton();
        });

        loginAsTeacher(this);
        verifyNoNewNotification();
      });
    });
  });

  describe("if the seminar has talks", () => {
    it("allows the user to successfully submit talks and become their speaker", function () {
      let talkIds;

      createTutorialsOrTalks(this, "talk");

      cy.then(() => {
        talkIds = [this.talk1.id, this.talk2.id];
      });

      cy.then(() => {
        submitVoucher(this.voucher);
        selectClaimsAndSubmit(talkIds);
      });

      verifyLectureIsSubscribed(this);

      cy.then(() => {
        loginAsTeacher(this);
        visitLectureContentEdit(this);
      });

      cy.then(() => {
        verifyClaimsContainUserName(this, "talk", talkIds);
      });

      cy.then(() => {
        verifyRoleNotification(this, "speaker"); ;
        cy.getBySelector("notification-body").should("contain", this.talk1.title)
          .and("contain", this.talk2.title);
      });
    });

    describe("and the user is already a speaker for all of them", () => {
      it("displays a message that the user is already a speaker for all talks", function () {
        createTutorialsOrTalks(this, "talk", this.user);

        cy.then(() => {
          submitVoucher(this.voucher);
        });

        cy.then(() => {
          verifyAllItemsTakenMessage(this, "talk");
          verifyCancelVoucherButton();
        });

        loginAsTeacher(this);
        verifyNoNotification();
      });
    });
  });
});
