import { test, expect } from "../_support/fixtures";
import { enableFeature } from "../_support/backend";
import {
  createReleasedLecture,
  createTutorialItemsCampaign,
  subscribeToLecture,
} from "./helpers";
import { CampaignRegistrationPage } from "../page-objects/campaign_registrations_page";

test.describe("campaign registration", () => {
  test.beforeEach(async ({ request }) => {
    await enableFeature(request, "registration_campaigns");
    await enableFeature(request, "roster_maintenance");
  });

  test("can be opened from the lecture enrollment tab", async ({ factory, student }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    await createTutorialItemsCampaign(
      factory,
      lecture,
      "first_come_first_served",
      "Tutorial registration",
    );

    await student.page.goto(`/lectures/${lecture.id}`);
    await student.page.getByRole("link", { name: "Enrollment" }).click();

    await expect(student.page.getByText("Tutorial registration")).toBeVisible();
    await expect(student.page.getByText("Register for a group.")).toBeVisible();
    await expect(student.page.getByRole("button", { name: "Register now" })).toHaveCount(3);
  });

  test("confirms and withdraws a first-come-first-served registration", async ({
    factory,
    student,
  }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    await createTutorialItemsCampaign(
      factory,
      lecture,
      "first_come_first_served",
      "Tutorial registration",
    );

    await new CampaignRegistrationPage(student.page, lecture.id).goto();

    await student.page.getByRole("button", { name: "Register now" }).first().click();

    await expect(student.page.getByText("Registration completed successfully.")).toBeVisible();
    await expect(student.page.getByRole("button", { name: "Withdraw" })).toHaveCount(1);
    await expect(student.page.getByText("Withdraw first")).toHaveCount(2);

    await student.page.getByRole("button", { name: "Withdraw" }).click();

    await expect(student.page.getByText("You have withdrawn your registration.")).toBeVisible();
    await expect(student.page.getByRole("button", { name: "Register now" })).toHaveCount(3);
  });

  test("keeps closed campaigns visible but read-only", async ({ factory, student }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    await createTutorialItemsCampaign(
      factory,
      lecture,
      "first_come_first_served",
      "Closed tutorial registration",
      "closed",
    );

    await new CampaignRegistrationPage(student.page, lecture.id).goto();

    await expect(student.page.getByText("Closed tutorial registration")).toBeVisible();
    await expect(student.page.getByText("Registration closed")).toBeVisible();
    await expect(student.page.getByRole("button", { name: "Register now" })).toHaveCount(3);

    const buttons = student.page.getByRole("button", { name: "Register now" });
    await expect(buttons.nth(0)).toBeDisabled();
    await expect(buttons.nth(1)).toBeDisabled();
    await expect(buttons.nth(2)).toBeDisabled();
  });

  test("explains email policy during registration", async ({ factory, student }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    await createTutorialItemsCampaign(
      factory,
      lecture,
      "first_come_first_served",
      "Email restricted tutorial registration",
      "open",
      1,
      ["with_policies"],
    );

    await new CampaignRegistrationPage(student.page, lecture.id).goto();

    const registerButton = student.page.getByRole("button", { name: "Register now" });
    await expect(student.page.getByText("Registration unavailable")).toBeVisible();
    await expect(student.page.getByText(
      "Your current email domain is play, but this registration process requires example.com",
    )).toBeVisible();
    await expect(registerButton).toHaveCount(1);
    await expect(registerButton).toBeDisabled();
  });

  test("explains prerequisite policies during registration", async ({
    factory,
    student,
  }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    const prerequisiteCampaign = await factory.create(
      "registration_campaign",
      ["completed", "first_come_first_served"],
      {
        allocation_mode: "first_come_first_served",
        campaignable_type: "Lecture",
        campaignable_id: lecture.id,
        description: "Priority registration",
        items_count: 1,
      },
    );
    await createTutorialItemsCampaign(
      factory,
      lecture,
      "first_come_first_served",
      "Follow-up tutorial registration",
      "open",
      1,
      ["with_prerequisite_policy"],
      { parent_campaign_id: prerequisiteCampaign.id },
    );

    await new CampaignRegistrationPage(student.page, lecture.id).goto();

    const registerButton = student.page.getByRole("button", { name: "Register now" });
    await expect(student.page.getByText("Registration unavailable")).toBeVisible();
    await expect(student.page.getByText(/You need a confirmed registration in .*Priority registration/))
      .toBeVisible();
    await expect(registerButton).toHaveCount(1);
    await expect(registerButton).toBeDisabled();
  });

  test("explains finalization policies and policy rejections", async ({
    factory,
    student,
  }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    const { campaign } = await createTutorialItemsCampaign(
      factory,
      lecture,
      "first_come_first_served",
      "Email checked tutorial registration",
      "open",
      1,
      ["with_finalization_policy"],
    );

    await new CampaignRegistrationPage(student.page, lecture.id).goto();

    await expect(student.page.getByText("Registration may be rejected")).toBeVisible();
    await expect(student.page.getByText(
      "Your current email domain is play, but this registration process requires example.com",
    )).toBeVisible();

    await student.page.getByRole("button", { name: "Register now" }).click();
    await expect(student.page.getByText("Registration completed successfully.")).toBeVisible();

    await campaign.__call("finalize!");
    await new CampaignRegistrationPage(student.page, lecture.id).goto();

    await expect(student.page.getByText(
      "Your registration for Email checked tutorial registration was rejected "
      + "for the following reasons:",
    )).toBeVisible();
    await expect(student.page.getByText(
      "At the time this registration process was finalized, your email domain "
      + "did not match the required email domains example.com.",
    )).toBeVisible();
    await expect(student.page.getByText(
      "Changing your email address afterwards does not automatically restore this registration.",
    )).toBeVisible();
    await expect(student.page.getByText(
      "If you still want to be admitted, please contact the lecturer or teaching assistant.",
    )).toBeVisible();
    await expect(student.page.getByText(
      "You are not registered in any group yet.",
    )).toHaveCount(0);
  });

  test("explains prerequisite policies during finalization and after rejection", async ({
    factory,
    student,
  }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    const prerequisiteCampaign = await factory.create(
      "registration_campaign",
      ["completed", "first_come_first_served"],
      {
        allocation_mode: "first_come_first_served",
        campaignable_type: "Lecture",
        campaignable_id: lecture.id,
        description: "Priority registration",
        items_count: 1,
      },
    );
    const { campaign } = await createTutorialItemsCampaign(
      factory,
      lecture,
      "first_come_first_served",
      "Follow-up tutorial registration",
      "open",
      1,
      ["with_finalization_prerequisite_policy"],
      { parent_campaign_id: prerequisiteCampaign.id },
    );

    await new CampaignRegistrationPage(student.page, lecture.id).goto();

    await expect(student.page.getByText("Registration may be rejected")).toBeVisible();
    await expect(student.page.getByText(/You need a confirmed registration in .*Priority registration/))
      .toBeVisible();

    await student.page.getByRole("button", { name: "Register now" }).click();
    await expect(student.page.getByText("Registration completed successfully.")).toBeVisible();

    await campaign.__call("finalize!");
    await new CampaignRegistrationPage(student.page, lecture.id).goto();

    await expect(student.page.getByText(
      "Your registration for Follow-up tutorial registration was rejected "
      + "for the following reasons:",
    )).toBeVisible();
    await expect(student.page.getByText(/You need a confirmed registration in .*Priority registration/))
      .toBeVisible();
  });

  test("stages preference ranks locally and saves them in one request", async ({
    factory,
    student,
  }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    const { campaign } = await createTutorialItemsCampaign(
      factory,
      lecture,
      "preference_based",
      "Preference tutorial registration",
    );
    let saveRequests = 0;
    let submittedBody = "";
    student.page.on("request", (request) => {
      if (request.url().includes(`/campaign_registrations/${campaign.id}/preferences`)) {
        saveRequests += 1;
        submittedBody = request.postData() || "";
      }
    });

    await new CampaignRegistrationPage(student.page, lecture.id).goto();

    const tiles = student.page.getByTestId("registration-group-tile");
    const firstTile = tiles.nth(0);
    const secondTile = tiles.nth(1);
    const thirdTile = tiles.nth(2);
    const preferencePodium = student.page.getByRole("group", {
      name: "Selected preference ranks",
    });
    const firstTitle = await firstTile.getByRole("heading").textContent();
    const secondTitle = await secondTile.getByRole("heading").textContent();
    const thirdTitle = await thirdTile.getByRole("heading").textContent();

    await expect(student.page.getByText("Rank 3 options.")).toBeVisible();
    const saveButton = student.page.getByRole("button", { name: "Save choices" });
    await expect(saveButton).toBeHidden();
    await firstTile.getByRole("button", { name: "1st" }).click();
    expect(saveRequests).toBe(0);
    await expect(firstTile.getByRole("button", { name: "1st" })).toHaveClass(/btn-primary/);
    await expect(preferencePodium).toContainText(firstTitle || "");
    await expect(saveButton).toBeDisabled();
    await expect(student.page.getByTestId("preference-save-tooltip"))
      .toHaveAttribute("title", "Choose an option for every rank before saving.");

    await secondTile.getByRole("button", { name: "2nd" }).click();
    await thirdTile.getByRole("button", { name: "3rd" }).click();
    expect(saveRequests).toBe(0);
    await expect(saveButton).toBeEnabled();

    await thirdTile.getByRole("button", { name: "1st" }).click();

    await expect(thirdTile.getByRole("button", { name: "1st" })).toHaveClass(/btn-primary/);
    await expect(secondTile.getByRole("button", { name: "2nd" })).toHaveClass(/btn-primary/);
    await expect(firstTile.getByRole("button", { name: "3rd" })).toHaveClass(/btn-primary/);
    await expect(student.page.getByRole("button", { pressed: true }))
      .toHaveCount(3);

    await saveButton.click();

    await expect(student.page.getByText("Your preferences have been saved.")).toBeVisible();
    await expect(saveButton).toBeHidden();
    expect(saveRequests).toBe(1);
    expect(submittedBody).toContain("preferences%5B1%5D");
    expect(submittedBody).toContain("preferences%5B2%5D");
    expect(submittedBody).toContain("preferences%5B3%5D");
    await expect(preferencePodium).toContainText(thirdTitle || "");
    await expect(preferencePodium).toContainText(secondTitle || "");
  });

  test("limits preference campaigns with two tutorials to two ranks", async ({
    factory,
    student,
  }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    const { campaign } = await createTutorialItemsCampaign(
      factory,
      lecture,
      "preference_based",
      "Two tutorial preference registration",
      "open",
      2,
    );
    let submittedBody = "";
    student.page.on("request", (request) => {
      if (request.url().includes(`/campaign_registrations/${campaign.id}/preferences`)) {
        submittedBody = request.postData() || "";
      }
    });

    await new CampaignRegistrationPage(student.page, lecture.id).goto();

    const tiles = student.page.getByTestId("registration-group-tile");
    const firstTile = tiles.nth(0);
    const secondTile = tiles.nth(1);
    const preferencePodium = student.page.getByRole("group", {
      name: "Selected preference ranks",
    });

    await expect(student.page.getByText("Rank 2 options.")).toBeVisible();
    await expect(preferencePodium.getByTestId("preference-podium-spot")).toHaveCount(2);
    await expect(student.page.getByRole("button", { name: "3rd" })).toHaveCount(0);
    await expect(student.page.getByRole("button", { name: "Save choices" })).toBeHidden();

    await firstTile.getByRole("button", { name: "1st" }).click();
    await secondTile.getByRole("button", { name: "2nd" }).click();
    await student.page.getByRole("button", { name: "Save choices" }).click();

    await expect(student.page.getByText("Your preferences have been saved.")).toBeVisible();
    expect(submittedBody).toContain("preferences%5B1%5D");
    expect(submittedBody).toContain("preferences%5B2%5D");
    expect(submittedBody).not.toContain("preferences%5B3%5D");
  });

  test("shows that the student is not assigned to any group yet", async ({
    factory,
    student,
  }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    await createTutorialItemsCampaign(
      factory,
      lecture,
      "first_come_first_served",
      "Tutorial registration",
    );

    await new CampaignRegistrationPage(student.page, lecture.id).goto();

    await expect(student.page.getByText(
      "You are not registered in any group yet.",
    )).toBeVisible();
    await expect(student.page.getByText("Tutorial registration")).toBeVisible();
  });

  test("explains that pending preferences will be allocated after registration closes", async ({
    factory,
    student,
  }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    const { campaign } = await createTutorialItemsCampaign(
      factory,
      lecture,
      "preference_based",
      "Preference tutorial registration",
    );
    const tutorial = await factory.create("tutorial", [], {
      lecture_id: lecture.id,
      title: "Pending Preference Tutorial",
      capacity: 2,
    });
    const item = await factory.create("registration_item", [], {
      registration_campaign_id: campaign.id,
      registerable_type: "Tutorial",
      registerable_id: tutorial.id,
    });

    await factory.create("registration_user_registration", [], {
      user_id: student.user.id,
      registration_campaign_id: campaign.id,
      registration_item_id: item.id,
      preference_rank: 1,
      status: "pending",
    });

    await new CampaignRegistrationPage(student.page, lecture.id).goto();

    await expect(student.page.getByText(
      "You are not registered in any group yet. After the registration period ends, you will be assigned based on your preferences.",
    )).toBeVisible();
    await expect(student.page.getByText("Your registration is confirmed for")).toHaveCount(0);
  });

  test("shows completed materialized assignments above remaining options", async ({
    factory,
    student,
  }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    const tutorial = await factory.create("tutorial", [], {
      lecture_id: lecture.id,
      title: "Assigned Tutorial",
      capacity: 2,
    });
    await factory.create("tutorial_membership", [], {
      tutorial_id: tutorial.id,
      user_id: student.user.id,
    });
    await createTutorialItemsCampaign(
      factory,
      lecture,
      "first_come_first_served",
      "Late tutorial registration",
    );

    await new CampaignRegistrationPage(student.page, lecture.id).goto();

    await expect(student.page.getByText("Your registration is confirmed for")).toBeVisible();
    await expect(student.page.getByText("Assigned Tutorial")).toBeVisible();
    await expect(student.page.getByText("Late tutorial registration")).toBeVisible();
  });

  test("disables registration options for a join-only assigned tutorial", async ({
    factory,
    student,
  }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    const tutorial = await factory.create("tutorial", [], {
      lecture_id: lecture.id,
      title: "Join-Only Assigned Tutorial",
      capacity: 2,
      skip_campaigns: true,
      self_materialization_mode: "add_only",
    });
    await factory.create("tutorial_membership", [], {
      tutorial_id: tutorial.id,
      user_id: student.user.id,
    });
    await factory.create("tutorial", [], {
      lecture_id: lecture.id,
      title: "Alternative Self Enrollment Tutorial",
      capacity: 2,
      skip_campaigns: true,
      self_materialization_mode: "add_only",
    });
    await createTutorialItemsCampaign(
      factory,
      lecture,
      "first_come_first_served",
      "Late tutorial registration",
    );

    await new CampaignRegistrationPage(student.page, lecture.id).goto();

    const assignedTutorialHeadings = student.page.getByRole("heading", {
      name: "Join-Only Assigned Tutorial",
    });
    await expect(assignedTutorialHeadings.first()).toBeVisible();
    await expect(student.page.getByText(
      "You cannot leave this tutorial because the lecturer has set it up this way.",
    )).toBeVisible();
    await expect(assignedTutorialHeadings).toHaveCount(2);
    await expect(student.page.getByText("Alternative Self Enrollment Tutorial")).toBeVisible();
    await expect(student.page.getByText("Late tutorial registration")).toBeVisible();
    await expect(student.page.getByRole("button", { name: "Register now" })).toHaveCount(0);

    const blockedTooltip
      = "You cannot join this tutorial since you cannot leave your tutorial. This was set up by your lecturer this way.";
    const alternativeTutorialTile = student.page.getByTestId("registration-group-tile").filter({
      has: student.page.getByRole("heading", {
        name: "Alternative Self Enrollment Tutorial",
      }),
    });
    await expect(alternativeTutorialTile).toHaveAttribute("title", blockedTooltip);

    const unavailableButtons = student.page.getByRole("button", { name: "Unavailable" });
    await expect(unavailableButtons).toHaveCount(4);

    for (let index = 0; index < 4; index += 1) {
      const unavailableButton = unavailableButtons.nth(index);
      const blockedAction = unavailableButton.locator("..");
      await expect(unavailableButton).toBeDisabled();
      await expect(blockedAction).toHaveAttribute("title", blockedTooltip);
    }
  });

  test("explains whether a materialized assignment fulfilled preferences", async ({
    factory,
    student,
    student2,
  }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    await subscribeToLecture(factory, lecture, student2.user.id);
    const campaign = await factory.create(
      "registration_campaign",
      ["completed", "preference_based"],
      {
        allocation_mode: "preference_based",
        campaignable_type: "Lecture",
        campaignable_id: lecture.id,
        description: "Allocated tutorial registration",
      },
    );
    const popularTutorial = await factory.create("tutorial", [], {
      lecture_id: lecture.id,
      title: "Popular Tutorial",
      capacity: 1,
    });
    const earlyTutorial = await factory.create("tutorial", [], {
      lecture_id: lecture.id,
      title: "Early Morning Tutorial",
      capacity: 1,
    });
    const lateTutorial = await factory.create("tutorial", [], {
      lecture_id: lecture.id,
      title: "Late Tutorial",
      capacity: 1,
    });
    const fallbackTutorial = await factory.create("tutorial", [], {
      lecture_id: lecture.id,
      title: "Fallback Tutorial",
      capacity: 1,
    });
    const popularItem = await factory.create("registration_item", [], {
      registration_campaign_id: campaign.id,
      registerable_type: "Tutorial",
      registerable_id: popularTutorial.id,
    });
    const earlyItem = await factory.create("registration_item", [], {
      registration_campaign_id: campaign.id,
      registerable_type: "Tutorial",
      registerable_id: earlyTutorial.id,
    });
    const lateItem = await factory.create("registration_item", [], {
      registration_campaign_id: campaign.id,
      registerable_type: "Tutorial",
      registerable_id: lateTutorial.id,
    });
    const fallbackItem = await factory.create("registration_item", [], {
      registration_campaign_id: campaign.id,
      registerable_type: "Tutorial",
      registerable_id: fallbackTutorial.id,
    });

    await factory.create("registration_user_registration", [], {
      user_id: student.user.id,
      registration_campaign_id: campaign.id,
      registration_item_id: popularItem.id,
      preference_rank: 1,
      status: "rejected",
    });
    await factory.create("registration_user_registration", [], {
      user_id: student.user.id,
      registration_campaign_id: campaign.id,
      registration_item_id: earlyItem.id,
      preference_rank: 2,
      status: "confirmed",
    });
    await factory.create("tutorial_membership", [], {
      tutorial_id: earlyTutorial.id,
      user_id: student.user.id,
      source_campaign_id: campaign.id,
    });

    await factory.create("registration_user_registration", [], {
      user_id: student2.user.id,
      registration_campaign_id: campaign.id,
      registration_item_id: popularItem.id,
      preference_rank: 1,
      status: "rejected",
    });
    await factory.create("registration_user_registration", [], {
      user_id: student2.user.id,
      registration_campaign_id: campaign.id,
      registration_item_id: earlyItem.id,
      preference_rank: 2,
      status: "rejected",
    });
    await factory.create("registration_user_registration", [], {
      user_id: student2.user.id,
      registration_campaign_id: campaign.id,
      registration_item_id: lateItem.id,
      preference_rank: 3,
      status: "rejected",
    });
    await factory.create("registration_user_registration", [], {
      user_id: student2.user.id,
      registration_campaign_id: campaign.id,
      registration_item_id: fallbackItem.id,
      preference_rank: null,
      status: "confirmed",
    });
    await factory.create("tutorial_membership", [], {
      tutorial_id: fallbackTutorial.id,
      user_id: student2.user.id,
      source_campaign_id: campaign.id,
    });

    await new CampaignRegistrationPage(student.page, lecture.id).goto();

    await expect(student.page.getByText(
      "We could fulfill your 2nd preference.",
    )).toBeVisible();
    await expect(student.page.getByRole("heading", {
      name: "Early Morning Tutorial",
    })).toBeVisible();
    await expect(student.page.getByText("Your registration is confirmed for")).toHaveCount(0);

    await new CampaignRegistrationPage(student2.page, lecture.id).goto();

    const unfulfilledNotice = [
      "Unfortunately, your preferences (1st Popular Tutorial, "
      + "2nd Early Morning Tutorial, 3rd Late Tutorial) could not be fulfilled.",
    ].join("");
    await expect(student2.page.getByText(unfulfilledNotice)).toBeVisible();
    await expect(student2.page.getByRole("heading", {
      name: "Fallback Tutorial",
    })).toBeVisible();
    await expect(student2.page.getByText("Your registration is confirmed for")).toHaveCount(0);
  });

  test("shows when preference campaigns could not allocate the student", async ({
    factory,
    student,
  }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    const campaign = await factory.create(
      "registration_campaign",
      ["completed", "preference_based"],
      {
        allocation_mode: "preference_based",
        campaignable_type: "Lecture",
        campaignable_id: lecture.id,
        description: "Overbooked tutorial registration",
      },
    );
    const tutorial = await factory.create("tutorial", [], {
      lecture_id: lecture.id,
      title: "Popular Tutorial",
      capacity: 1,
    });
    const secondPreferenceTutorial = await factory.create("tutorial", [], {
      lecture_id: lecture.id,
      title: "Early Morning Tutorial",
      capacity: 1,
    });

    const item = await factory.create("registration_item", [], {
      registration_campaign_id: campaign.id,
      registerable_type: "Tutorial",
      registerable_id: tutorial.id,
    });
    const secondPreferenceItem = await factory.create("registration_item", [], {
      registration_campaign_id: campaign.id,
      registerable_type: "Tutorial",
      registerable_id: secondPreferenceTutorial.id,
    });

    await factory.create("registration_user_registration", [], {
      user_id: student.user.id,
      registration_campaign_id: campaign.id,
      registration_item_id: item.id,
      preference_rank: 1,
      status: "rejected",
    });
    await factory.create("registration_user_registration", [], {
      user_id: student.user.id,
      registration_campaign_id: campaign.id,
      registration_item_id: secondPreferenceItem.id,
      preference_rank: 2,
      status: "rejected",
    });

    const secondCampaign = await factory.create(
      "registration_campaign",
      ["completed", "preference_based"],
      {
        allocation_mode: "preference_based",
        campaignable_type: "Lecture",
        campaignable_id: lecture.id,
        description: "Backup tutorial registration",
      },
    );
    const secondTutorial = await factory.create("tutorial", [], {
      lecture_id: lecture.id,
      title: "Quiet Tutorial",
      capacity: 1,
    });
    const secondItem = await factory.create("registration_item", [], {
      registration_campaign_id: secondCampaign.id,
      registerable_type: "Tutorial",
      registerable_id: secondTutorial.id,
    });
    await factory.create("registration_user_registration", [], {
      user_id: student.user.id,
      registration_campaign_id: secondCampaign.id,
      registration_item_id: secondItem.id,
      preference_rank: 1,
      status: "rejected",
    });

    await new CampaignRegistrationPage(student.page, lecture.id).goto();

    const unallocatedMessages = student.page.getByText(
      /Unfortunately, your registration for .* could not be considered/,
    );
    await expect(unallocatedMessages).toHaveCount(2);

    // first campaign
    await expect(student.page.getByText(/Overbooked tutorial registration/)).toBeVisible();
    await expect(student.page.getByText(
      "1st Popular Tutorial, 2nd Early Morning Tutorial",
    )).toBeVisible();
    // second campaign
    await expect(student.page.getByText(/Backup tutorial registration/)).toBeVisible();
    await expect(student.page.getByText("1st Quiet Tutorial")).toBeVisible();

    await expect(student.page.getByText("Registration result")).toHaveCount(0);
    await expect(student.page.getByText(
      "There are currently no tutorials or groups available for registration.",
    )).toBeVisible();
  });
});
