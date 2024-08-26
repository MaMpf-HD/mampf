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

function verifyNoTutorialsYetMessage(context) {
  cy.i18n("profile.no_tutorials_yet").as("no_tutorials_yet");

  cy.then(() => {
    cy.getBySelector("redeem-voucher-card").should("contain", context.no_tutorials_yet);
    cy.getBySelector("redeem-voucher-btn").should("be.visible");
  });
}

function verifyAlreadyRedeemedTutorVoucherMessage(context) {
  cy.i18n("profile.already_tutor_by_redemption").as("alreadyRedeemedTutorVoucher");

  cy.then(() => {
    cy.getBySelector("redeem-voucher-card").should("contain", context.alreadyRedeemedTutorVoucher);
  });
}

function redeemVoucherToBecomeTutor(context) {
  cy.i18n("controllers.become_tutor_success").as("becomeTutorSuccess");
  cy.getBySelector("redeem-voucher-btn").click();
  cy.then(() => {
    cy.getBySelector("flash-notice").should("be.visible")
      .and("contain", context.becomeTutorSuccess);
  });
}

function createTutorials(context) {
  FactoryBot.create("tutorial", { lecture_id: context.lecture.id }).as("tutorial1");
  FactoryBot.create("tutorial", { lecture_id: context.lecture.id }).as("tutorial2");
  FactoryBot.create("tutorial", { lecture_id: context.lecture.id }).as("tutorial3");
}

function createTutorialsWithTutor(context, tutor) {
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

function verifyTutorialsContainTutorName(context, tutorialIds) {
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

function verifyTutorNotification(context) {
  cy.i18n("basics.tutor").as("tutorMessage");
  cy.i18n("notifications.redemption").as("redemptionMessage");

  cy.then(() => {
    cy.visit("/main/start");
    cy.getBySelector("notification-dropdown").should("be.visible");
    cy.getBySelector("notification-dropdown-counter").should("contain", "1");
    cy.getBySelector("notification-dropdown-menu").should("contain", context.tutorMessage)
      .and("contain", context.user.name_in_tutorials);
    cy.visit("/notifications");
    cy.getBySelector("notification-card").should("have.length", 1);
    cy.getBySelector("notification-header").should("contain", context.lecture.title_for_viewers);
    cy.getBySelector("notification-body").should("contain", context.redemptionMessage)
      .and("contain", context.user.name_in_tutorials).and("contain", context.user.email);
  });
}

function verifyAllTutorialsTakenMessage(context) {
  cy.i18n("profile.all_tutorials_taken").as("all_tutorials_taken");

  cy.then(() => {
    cy.getBySelector("redeem-voucher-card").should("contain", context.all_tutorials_taken)
      .and("contain", context.tutorial1.title).and("contain", context.tutorial2.title)
      .and("contain", context.tutorial3.title);
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

function redeemVoucherToBecomeEditor(context) {
  cy.i18n("controllers.become_editor_success").as("becomeEditorSuccess");
  cy.getBySelector("redeem-voucher-btn").click();
  cy.then(() => {
    cy.getBySelector("flash-notice").should("be.visible")
      .and("contain", context.becomeEditorSuccess);
  });
}

function verifyEditorNotification(context) {
  cy.i18n("basics.editor").as("editorMessage");
  cy.i18n("notifications.redemption").as("redemptionMessage");

  cy.then(() => {
    cy.visit("/main/start");
    cy.getBySelector("notification-dropdown").should("be.visible");
    cy.getBySelector("notification-dropdown-counter").should("contain", "1");
    cy.getBySelector("notification-dropdown-menu").should("contain", context.editorMessage)
      .and("contain", context.user.name_in_tutorials);
    cy.visit("/notifications");
    cy.getBySelector("notification-card").should("have.length", 1);
    cy.getBySelector("notification-header").should("contain", context.lecture.title_for_viewers);
    cy.getBySelector("notification-body").should("contain", context.redemptionMessage)
      .and("contain", context.user.name_in_tutorials).and("contain", context.user.email);
  });
}

function verifyAlreadyRedeemedEditorVoucherMessage(context) {
  cy.i18n("profile.already_editor_by_redemption").as("alreadyRedeemedEditorVoucher");

  cy.then(() => {
    cy.getBySelector("redeem-voucher-card").should("contain", context.alreadyRedeemedEditorVoucher);
  });
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

function redeemVoucherToBecomeTeacher(context) {
  cy.i18n("controllers.become_teacher_success").as("becomeTeacherSuccess");
  cy.getBySelector("redeem-voucher-btn").click();
  cy.then(() => {
    cy.getBySelector("flash-notice").should("be.visible")
      .and("contain", context.becomeTeacherSuccess);
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

function verifyNoTalksYetMessage(context) {
  cy.i18n("profile.no_talks_yet").as("noTalksYet");

  cy.then(() => {
    cy.getBySelector("redeem-voucher-card").should("contain", context.noTalksYet);
    cy.getBySelector("redeem-voucher-btn").should("be.visible");
  });
}

function redeemVoucherToBecomeSpeaker(context) {
  cy.i18n("controllers.become_speaker_success").as("becomeSpeakerSuccess");
  cy.getBySelector("redeem-voucher-btn").click();
  cy.then(() => {
    cy.getBySelector("flash-notice").should("be.visible")
      .and("contain", context.becomeSpeakerSuccess);
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

function verifySpeakerNotification(context) {
  cy.i18n("basics.speaker").as("speakerMessage");
  cy.i18n("notifications.redemption").as("redemptionMessage");

  cy.then(() => {
    cy.visit("/main/start");
    cy.getBySelector("notification-dropdown").should("be.visible");
    cy.getBySelector("notification-dropdown-counter").should("contain", "1");
    cy.getBySelector("notification-dropdown-menu").should("contain", context.speakerMessage)
      .and("contain", context.user.name_in_tutorials);
    cy.visit("/notifications");
    cy.getBySelector("notification-card").should("have.length", 1);
    cy.getBySelector("notification-header").should("contain", context.lecture.title_for_viewers);
    cy.getBySelector("notification-body").should("contain", context.redemptionMessage)
      .and("contain", context.user.name_in_tutorials).and("contain", context.user.email);
  });
}

function verifyAlreadyRedeemedSpeakerVoucherMessage(context) {
  cy.i18n("profile.already_speaker_by_redemption").as("alreadyRedeemedSpeakerVoucher");

  cy.then(() => {
    cy.getBySelector("redeem-voucher-card")
      .should("contain", context.alreadyRedeemedSpeakerVoucher);
  });
}

function createTalks(context) {
  FactoryBot.create("talk", { lecture_id: context.lecture.id }).as("talk1");
  FactoryBot.create("talk", { lecture_id: context.lecture.id }).as("talk2");
  FactoryBot.create("talk", { lecture_id: context.lecture.id }).as("talk3");
}

function createTalksWithSpeaker(context) {
  FactoryBot.create("talk", { lecture_id: context.lecture.id, speaker_ids: [context.user.id] })
    .as("talk1");
  FactoryBot.create("talk", { lecture_id: context.lecture.id, speaker_ids: [context.user.id] })
    .as("talk2");
  FactoryBot.create("talk", { lecture_id: context.lecture.id, speaker_ids: [context.user.id] })
    .as("talk3");
}

function selectTalksAndSubmit(talkIds) {
  const talkIdsAsStrings = talkIds.map(id => id.toString());

  cy.getBySelector("claim-select").should("be.visible");
  cy.getBySelector("claim-select").select(talkIdsAsStrings, { force: true });
  cy.getBySelector("claim-submit").click();
  cy.getBySelector("flash-notice").should("be.visible");
}

function verifyTalksContainSpeakerName(context, talkIds) {
  cy.getBySelector("talk-header").should("have.length", 3).each(($el) => {
    const dataId = parseInt($el.attr("data-id"), 10);
    if (talkIds.includes(dataId)) {
      cy.wrap($el).should("contain", context.user.name_in_tutorials);
    }
    else {
      cy.wrap($el).should("not.contain", context.user.name_in_tutorials);
    }
  });
}

function verifyAllTalksTakenMessage(context) {
  cy.i18n("profile.all_talks_taken").as("allTalksTaken");

  cy.then(() => {
    cy.getBySelector("redeem-voucher-card").should("contain", context.allTalksTaken)
      .and("contain", context.talk1.title).and("contain", context.talk2.title)
      .and("contain", context.talk3.title);
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
      verifyNoTutorialsYetMessage(this);

      cy.then(() => {
        redeemVoucherToBecomeTutor(this);
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
        verifyTutorNotification(this);
        cy.i18n("notifications.no_tutorials_taken").as("noTutorialsTaken");
        cy.then(() => {
          cy.getBySelector("notification-body").should("contain", this.noTutorialsTaken);
        });
      });
    });

    describe("and the user has already redeemed the voucher", () => {
      it("displays a message that the user has already redeemed the voucher", function () {
        submitVoucher(this.voucher);
        redeemVoucherToBecomeTutor(this);

        // redeem the voucher again
        cy.then(() => {
          submitVoucher(this.voucher);
          verifyAlreadyRedeemedTutorVoucherMessage(this);
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

      createTutorials(this);

      cy.then(() => {
        tutorialIds = [this.tutorial1.id, this.tutorial2.id];
      });

      cy.then(() => {
        submitVoucher(this.voucher);
        selectTutorialsAndSubmit(tutorialIds);
      });

      cy.then(() => {
        verifyLectureIsSubscribed(this);
      });

      cy.then(() => {
        loginAsTeacher(this);
        visitLectureEdit(this);
      });

      cy.then(() => {
        verifyTutorialsContainTutorName(this, tutorialIds);
      });

      cy.then(() => {
        verifyTutorNotification(this);
        cy.getBySelector("notification-body").should("contain", this.tutorial1.title)
          .and("contain", this.tutorial2.title);
      });
    });

    describe("and the user is already a tutor for all of them", () => {
      it("displays a message that the user is already a tutor for all tutorials", function () {
        createTutorialsWithTutor(this, this.user);

        cy.then(() => {
          submitVoucher(this.voucher);
        });

        cy.then(() => {
          verifyAllTutorialsTakenMessage(this);
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
    redeemVoucherToBecomeEditor(this);

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
      verifyEditorNotification(this);
    });
  });

  describe("if the user has already redeemed the voucher", () => {
    it("displays a message that the user has already redeemed the voucher", function () {
      submitVoucher(this.voucher);
      redeemVoucherToBecomeEditor(this);

      // redeem the voucher again
      cy.then(() => {
        submitVoucher(this.voucher);
        verifyAlreadyRedeemedEditorVoucherMessage(this);
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
    redeemVoucherToBecomeTeacher(this);

    verifyLectureIsSubscribed(this);
    visitLectureEdit(this);
    verifyUserIsTeacher(this);
    verifyPreviousTeacherIsEditor(this);
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
      verifyNoTalksYetMessage(this);
      redeemVoucherToBecomeSpeaker(this);
      verifyLectureIsSubscribed(this);

      cy.then(() => {
        loginAsTeacher(this);
        visitLectureContentEdit(this);
      });

      cy.then(() => {
        verifyNoTalksYetButUserEligibleAsSpeaker(this);
      });

      cy.then(() => {
        verifySpeakerNotification(this);
        cy.i18n("notifications.no_talks_taken").as("noTalksTaken");
        cy.then(() => {
          cy.getBySelector("notification-body").should("contain", this.noTalksTaken);
        });
      });
    });

    describe("and the user has already redeemed the voucher", () => {
      it("displays a message that the user has already redeemed the voucher", function () {
        submitVoucher(this.voucher);
        redeemVoucherToBecomeSpeaker(this);

        // redeem the voucher again
        cy.then(() => {
          submitVoucher(this.voucher);
          verifyAlreadyRedeemedSpeakerVoucherMessage(this);
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

      createTalks(this);

      cy.then(() => {
        talkIds = [this.talk1.id, this.talk2.id];
      });

      cy.then(() => {
        submitVoucher(this.voucher);
        selectTalksAndSubmit(talkIds);
      });

      verifyLectureIsSubscribed(this);

      cy.then(() => {
        loginAsTeacher(this);
        visitLectureContentEdit(this);
      });

      cy.then(() => {
        verifyTalksContainSpeakerName(this, talkIds);
      });

      cy.then(() => {
        verifySpeakerNotification(this);
        cy.getBySelector("notification-body").should("contain", this.talk1.title)
          .and("contain", this.talk2.title);
      });
    });

    describe("and the user is already a speaker for all of them", () => {
      it("displays a message that the user is already a speaker for all talks", function () {
        createTalksWithSpeaker(this);

        cy.then(() => {
          submitVoucher(this.voucher);
        });

        cy.then(() => {
          verifyAllTalksTakenMessage(this);
          verifyCancelVoucherButton();
        });

        loginAsTeacher(this);
        verifyNoNotification();
      });
    });
  });
});
