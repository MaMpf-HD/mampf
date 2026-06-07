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

    const firstTile = student.page.locator(".tutorial-gtile").first();
    await firstTile.getByRole("button", { name: "Register now" }).click();

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

    const firstTile = student.page.locator(".tutorial-gtile").nth(0);
    const secondTile = student.page.locator(".tutorial-gtile").nth(1);
    const thirdTile = student.page.locator(".tutorial-gtile").nth(2);
    const firstTitle = await firstTile.getByRole("heading").textContent();
    const secondTitle = await secondTile.getByRole("heading").textContent();
    const thirdTitle = await thirdTile.getByRole("heading").textContent();

    await expect(student.page.getByText("Rank 3 options.")).toBeVisible();
    const saveButton = student.page.getByRole("button", { name: "Save choices" });
    await expect(saveButton).toBeHidden();
    await firstTile.getByRole("button", { name: "1st" }).click();
    expect(saveRequests).toBe(0);
    await expect(firstTile.getByRole("button", { name: "1st" })).toHaveClass(/btn-primary/);
    await expect(student.page.locator(".student-registration-podium")).toContainText(
      firstTitle || "",
    );
    await expect(saveButton).toBeDisabled();

    await secondTile.getByRole("button", { name: "2nd" }).click();
    await thirdTile.getByRole("button", { name: "3rd" }).click();
    expect(saveRequests).toBe(0);
    await expect(saveButton).toBeEnabled();

    await thirdTile.getByRole("button", { name: "1st" }).click();

    await expect(thirdTile.getByRole("button", { name: "1st" })).toHaveClass(/btn-primary/);
    await expect(secondTile.getByRole("button", { name: "2nd" })).toHaveClass(/btn-primary/);
    await expect(firstTile.getByRole("button", { name: "3rd" })).toHaveClass(/btn-primary/);
    await expect(student.page.locator(".student-registration-rank-button.btn-primary"))
      .toHaveCount(3);

    await saveButton.click();

    await expect(student.page.getByText("Your preferences have been saved.")).toBeVisible();
    await expect(saveButton).toBeHidden();
    expect(saveRequests).toBe(1);
    expect(submittedBody).toContain("preferences%5B1%5D");
    expect(submittedBody).toContain("preferences%5B2%5D");
    expect(submittedBody).toContain("preferences%5B3%5D");
    await expect(student.page.locator(".student-registration-podium")).toContainText(
      thirdTitle || "",
    );
    await expect(student.page.locator(".student-registration-podium")).toContainText(
      secondTitle || "",
    );
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

    const firstTile = student.page.locator(".tutorial-gtile").nth(0);
    const secondTile = student.page.locator(".tutorial-gtile").nth(1);

    await expect(student.page.getByText("Rank 2 options.")).toBeVisible();
    await expect(student.page.locator(".student-registration-podium-spot")).toHaveCount(2);
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

    await factory.create("registration_user_registration", [], {
      user_id: student.user.id,
      registration_campaign_id: campaign.id,
      registration_item_id: campaign.registration_items[0].id,
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

    const notice = student.page.locator(".student-registration-rosterized-notice");
    await expect(notice).toHaveCount(1);
    await expect(notice.locator(".student-registration-rosterized-message")).toHaveCount(2);

    // first campaign
    await expect(notice).toContainText("Overbooked tutorial registration");
    await expect(notice).toContainText(
      "1st Popular Tutorial, 2nd Early Morning Tutorial",
    );
    // second campaign
    await expect(notice).toContainText("Backup tutorial registration");
    await expect(notice).toContainText("1st Quiet Tutorial");

    await expect(student.page.getByText("Registration result")).toHaveCount(0);
    await expect(student.page.getByText(
      "There are currently no tutorials or groups available for registration.",
    )).toHaveCount(0);
  });
});
