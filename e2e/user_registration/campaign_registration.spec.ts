import { Page, test, expect } from "../_support/fixtures";
import { confirmationLinkFor } from "../_support/mail";
import {
  createReleasedLecture,
  createTutorialItemsCampaign,
  subscribeToLecture,
} from "./helpers";
import { CampaignRegistrationPage } from "../page-objects/campaign_registrations_page";
import { ProfilePage } from "../page-objects/profile_page";
import { FactoryBot, FactoryBotObject } from "../_support/factorybot";

async function createTeacherOwnedReleasedLecture(
  factory: FactoryBot,
  teacherId: number,
): Promise<FactoryBotObject> {
  const course = await factory.create("course", [], {
    title: "Advanced Calculus",
  });
  return factory.create("lecture", ["released_for_all"], {
    course_id: course.id,
    teacher_id: teacherId,
  });
}

async function admitRejectedStudentThroughTeacherRoster(
  page: Page,
  lectureId: number,
  campaign: FactoryBotObject,
  tutorialTitle: string,
  studentEmail: string,
): Promise<void> {
  await page.goto(`/lectures/${lectureId}/edit?tab=groups`);

  const campaignBar = page.locator(`#dissolved_campaign_${campaign.id}`);
  await campaignBar.getByRole("button", { name: /1 rejected/ }).click();
  await expect(page.getByRole("heading", { name: "Rejected Registrations" }))
    .toBeVisible();

  const rejectedStudent = page.locator(".tutorial-roster-student", {
    hasText: studentEmail,
  });
  const targetTutorial = page.locator(".tutorial-gtile").filter({
    has: page.getByRole("heading", { name: tutorialTitle }),
  });

  await expect(rejectedStudent).toBeVisible();
  await expect(targetTutorial).toBeVisible();
  await rejectedStudent.dragTo(targetTutorial);

  await expect(campaignBar.getByRole("button", { name: /1 rejected/ })).toHaveCount(0);
}

test.describe("campaign registration", () => {
  test("can be opened from the lecture home tab", async ({ factory, student }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    await createTutorialItemsCampaign(
      factory,
      lecture,
      "first_come_first_served",
      "Tutorial registration",
    );

    await student.page.goto(`/lectures/${lecture.id}`);
    await student.page.getByRole("link", { name: "Home" }).click();

    const home = new CampaignRegistrationPage(student.page, lecture.id);
    await expect(student.page.getByRole("region", { name: "Registration open" })
      .getByRole("heading", { name: "Tutorial registration" })).toBeVisible();
    await expect(home.campaign("Tutorial registration")).toContainText("Not registered yet");
    await expect(student.page.getByText("Register for a group.")).toBeHidden();

    await home.openCampaign("Tutorial registration");
    await expect(student.page.getByText("Register for a group.")).toBeVisible();
    await expect(home.registerButtons()).toHaveCount(3);
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

    const home = new CampaignRegistrationPage(student.page, lecture.id);
    await home.goto();
    await home.openCampaign("Tutorial registration");

    await home.register();

    await expect(student.page.getByText("Registration completed successfully.")).toBeVisible();
    await expect(student.page.getByRole("button", { name: /^Withdraw from / })).toHaveCount(1);
    await expect(student.page.getByRole("button", { name: /^Switch to / })).toHaveCount(2);
    await expect(home.campaign("Tutorial registration")).toContainText("Registered");
    await expect(home.campaign("Tutorial registration").locator("summary")).toBeFocused();

    await home.withdraw();

    await expect(student.page.getByText("You have withdrawn your registration.")).toBeVisible();
    await expect(home.registerButtons()).toHaveCount(3);
    await expect(home.campaign("Tutorial registration")).toContainText("Not registered yet");
  });

  test("switches a first come, first served registration to another group", async ({
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

    const home = new CampaignRegistrationPage(student.page, lecture.id);
    await home.goto();
    await home.openCampaign("Tutorial registration");
    await home.register();
    await expect(student.page.getByText("Registration completed successfully.")).toBeVisible();

    const switchButton = student.page.getByRole("button", { name: /^Switch to / }).first();
    const target = (await switchButton.getAttribute("aria-label"))?.replace(/^Switch to /, "");
    await switchButton.click();

    await expect(student.page.getByText("You have switched groups.")).toBeVisible();
    await expect(home.campaign("Tutorial registration")).toContainText("Registered");
    await expect(home.campaign("Tutorial registration").locator("summary"))
      .toContainText(target || "");
    await expect(student.page.getByRole("button", { name: `Withdraw from ${target}` }))
      .toBeVisible();
  });

  test("opens a campaign that a link points at", async ({ factory, student }) => {
    const lecture = await createReleasedLecture(factory);
    await subscribeToLecture(factory, lecture, student.user.id);
    const { campaign } = await createTutorialItemsCampaign(
      factory,
      lecture,
      "first_come_first_served",
      "Tutorial registration",
    );

    const home = new CampaignRegistrationPage(student.page, lecture.id);
    await home.goto();
    await expect(home.campaign("Tutorial registration")).not.toHaveAttribute("open", "");

    await student.page.goto(
      `/lectures/${lecture.id}/home#student_registration_registration_campaign_${campaign.id}`,
    );

    await expect(home.campaign("Tutorial registration")).toHaveAttribute("open", "");
    await expect(home.registerButtons()).toHaveCount(3);
  });

  test("shows the first options of a long list and finds the others by search", async ({
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
      "open",
      10,
    );

    const home = new CampaignRegistrationPage(student.page, lecture.id);
    await home.goto();
    const fold = await home.openCampaign("Tutorial registration");
    const options = fold.getByTestId("registration-option");

    await expect(options.filter({ visible: true })).toHaveCount(8);
    const hiddenLabel = await fold
      .getByRole("button", { name: /^Register for /, includeHidden: true })
      .nth(9)
      .getAttribute("aria-label");
    const hiddenTitle = hiddenLabel?.replace(/^Register for /, "") || "";

    await fold.getByRole("searchbox", { name: "Search options" }).fill(hiddenTitle);
    await expect(options.filter({ visible: true })).toHaveCount(1);
    await expect(fold.getByRole("button", { name: hiddenLabel || "" })).toBeVisible();

    await fold.getByRole("searchbox", { name: "Search options" }).fill("");
    await fold.getByRole("button", { name: "Show all 10" }).click();
    await expect(options.filter({ visible: true })).toHaveCount(10);
  });

  test("lists closed campaigns without registration buttons", async ({ factory, student }) => {
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

    await student.page.getByText("Past registrations (1)").click();
    await expect(student.page.getByText("Closed tutorial registration")).toBeVisible();
    await expect(student.page.getByTestId("lecture-home-history"))
      .toContainText("Registration ended on");
    await expect(student.page.getByRole("button", { name: /^Register/ })).toHaveCount(0);
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

    const home = new CampaignRegistrationPage(student.page, lecture.id);
    await home.goto();
    await expect(home.campaign("Email restricted tutorial registration"))
      .toContainText("Requirement missing");
    await home.openCampaign("Email restricted tutorial registration");

    const registerButton = student.page.getByRole("button", { name: "Register now" });
    await expect(student.page.getByText("Registration unavailable")).toBeVisible();
    await expect(student.page.getByText(
      "Your current email domain is play, but this registration process requires example.com",
    ).first()).toBeVisible();
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

    const home = new CampaignRegistrationPage(student.page, lecture.id);
    await home.goto();
    await home.openCampaign("Follow-up tutorial registration");

    const registerButton = student.page.getByRole("button", { name: "Register now" });
    await expect(student.page.getByText("Registration unavailable")).toBeVisible();
    await expect(student.page.getByText(/You need a confirmed registration in .*Priority registration/)
      .first()).toBeVisible();
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

    const home = new CampaignRegistrationPage(student.page, lecture.id);
    await home.goto();
    await home.openCampaign("Email checked tutorial registration");

    await expect(student.page.getByText(
      "You can still register now. The requirements that are currently not fulfilled "
      + "are shown below.",
    )).toBeVisible();
    await student.page.getByText("Policy checks for this registration").click();
    await expect(student.page.getByText(
      "Current domain: play. Update your email in Profile before the final allocation.",
    )).toBeVisible();

    await home.register();
    await expect(student.page.getByText("Registration completed successfully.")).toBeVisible();

    await campaign.__call("finalize!");
    await home.goto();

    await expect(home.participation("Email checked tutorial registration")).toContainText("Rejected");
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

    const home = new CampaignRegistrationPage(student.page, lecture.id);
    await home.goto();
    await home.openCampaign("Follow-up tutorial registration");

    await expect(student.page.getByText(
      "You can still register now. The requirements that are currently not fulfilled "
      + "are shown below.",
    )).toBeVisible();
    await student.page.getByText("Policy checks for this registration").click();
    await expect(student.page.getByText(
      /Complete .*Priority registration successfully before the final allocation/,
    )).toBeVisible();

    await home.register();
    await expect(student.page.getByText("Registration completed successfully.")).toBeVisible();

    await campaign.__call("finalize!");
    await home.goto();

    await expect(home.participation("Follow-up tutorial registration")).toContainText("Rejected");
    await expect(student.page.getByText(
      /At the time this registration process was finalized, you did not have a confirmed registration in .*Priority registration/,
    ))
      .toBeVisible();
  });

  test("keeps the finalization rejection reason after the prerequisite is met later", async ({
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

    // The student registers for the follow-up campaign without having a
    // confirmed registration in the prerequisite campaign yet.
    const home = new CampaignRegistrationPage(student.page, lecture.id);
    await home.goto();
    await home.openCampaign("Follow-up tutorial registration");
    await home.register();
    await expect(student.page.getByText("Registration completed successfully.")).toBeVisible();

    // Finalizing the follow-up campaign rejects the student because the
    // prerequisite was not met at that point in time.
    await campaign.__call("finalize!");
    await home.goto();
    await expect(home.participation("Follow-up tutorial registration")).toContainText("Rejected");
    await expect(student.page.getByText(
      /At the time this registration process was finalized, you did not have a confirmed registration in .*Priority registration/,
    )).toBeVisible();

    // The student now fulfills the prerequisite *after* the follow-up campaign
    // was already finalized: they obtain a confirmed registration in the
    // prerequisite campaign.
    const prerequisiteTutorial = await factory.create("tutorial", [], {
      lecture_id: lecture.id,
      title: "Priority Tutorial",
      capacity: 5,
    });
    const prerequisiteItem = await factory.create("registration_item", [], {
      registration_campaign_id: prerequisiteCampaign.id,
      registerable_type: "Tutorial",
      registerable_id: prerequisiteTutorial.id,
    });
    await factory.create("registration_user_registration", [], {
      user_id: student.user.id,
      registration_campaign_id: prerequisiteCampaign.id,
      registration_item_id: prerequisiteItem.id,
      status: "confirmed",
    });

    // Reloading the already-finalized follow-up campaign must NOT retroactively
    // un-reject the student or re-evaluate the policy against their current
    // state. The historical finalization rejection reason stays, and the
    // student is not shown as registered/confirmed in the follow-up campaign.
    await home.goto();
    await expect(home.participation("Follow-up tutorial registration")).toContainText("Rejected");
    await expect(student.page.getByText(
      /At the time this registration process was finalized, you did not have a confirmed registration in .*Priority registration/,
    )).toBeVisible();
    await expect(home.participation("Assigned")).toHaveCount(0);
  });

  test("keeps the finalization email rejection after the email is fixed later", async ({
    factory,
    student,
    request,
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

    // The student registers while their email domain does not satisfy the
    // finalization email policy yet.
    const home = new CampaignRegistrationPage(student.page, lecture.id);
    await home.goto();
    await home.openCampaign("Email checked tutorial registration");
    await home.register();
    await expect(student.page.getByText("Registration completed successfully.")).toBeVisible();

    // Finalizing rejects the student because their email domain did not match
    // at that point in time.
    await campaign.__call("finalize!");
    await home.goto();
    await expect(home.participation("Email checked tutorial registration")).toContainText("Rejected");
    await expect(student.page.getByText(
      "At the time this registration process was finalized, your email domain "
      + "did not match the required email domains example.com.",
    )).toBeVisible();

    // The student now fixes their email *after* the campaign was finalized:
    // they change it to an allowed domain and confirm the change.
    const newEmail = `fixed_${Date.now()}@example.com`;
    await new ProfilePage(student.page).goto();
    await student.page.getByRole("link", { name: "Change login data" }).click();
    await student.page.locator("#user_email").fill(newEmail);
    await student.page.getByLabel("Current password", { exact: true })
      .fill(student.user.password);
    await student.page.getByRole("button", { name: "Save" }).click();
    await expect(student.page.getByRole("alert")).toBeVisible();

    const confirmationLink = await confirmationLinkFor(request, newEmail);
    await student.page.goto(confirmationLink);

    // Even though the email now satisfies the policy, the already-finalized
    // campaign must keep the historical rejection: the decision is frozen and
    // not re-evaluated against the current email.
    await home.goto();
    await expect(home.participation("Email checked tutorial registration")).toContainText("Rejected");
    await expect(student.page.getByText(
      "At the time this registration process was finalized, your email domain "
      + "did not match the required email domains example.com.",
    )).toBeVisible();
    await expect(home.participation("Assigned")).toHaveCount(0);
  });

  test("hides a finalized policy rejection after manual admission overrides it", async ({
    factory,
    student,
    teacher,
  }) => {
    const lecture = await createTeacherOwnedReleasedLecture(factory, teacher.user.id);
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

    const home = new CampaignRegistrationPage(student.page, lecture.id);
    await home.goto();
    await home.openCampaign("Email checked tutorial registration");
    const registerLabel = await home.registerButtons().first().getAttribute("aria-label");
    const assignedTutorialTitle = registerLabel?.replace(/^Register for /, "") || "";
    expect(assignedTutorialTitle).toBeTruthy();

    await home.register();
    await expect(student.page.getByText("Registration completed successfully.")).toBeVisible();

    await campaign.__call("finalize!");
    await home.goto();
    await expect(home.participation("Email checked tutorial registration")).toContainText("Rejected");

    await admitRejectedStudentThroughTeacherRoster(
      teacher.page,
      lecture.id,
      campaign,
      assignedTutorialTitle,
      student.user.email,
    );

    await home.goto();
    await expect(home.participation(assignedTutorialTitle)).toContainText("Assigned");
    await expect(home.participation("Email checked tutorial registration")).toHaveCount(0);
    await expect(student.page.getByText(
      "At the time this registration process was finalized",
    )).toHaveCount(0);
  });

  test("keeps unrelated policy rejections visible after another override", async ({
    factory,
    student,
    teacher,
  }) => {
    const lecture = await createTeacherOwnedReleasedLecture(factory, teacher.user.id);
    await subscribeToLecture(factory, lecture, student.user.id);
    const { campaign: overriddenCampaign } = await createTutorialItemsCampaign(
      factory,
      lecture,
      "first_come_first_served",
      "Resolved tutorial registration",
      "open",
      1,
      ["with_finalization_policy"],
    );
    const { campaign: unrelatedCampaign } = await createTutorialItemsCampaign(
      factory,
      lecture,
      "first_come_first_served",
      "Additional tutorial registration",
      "open",
      1,
      ["with_finalization_policy"],
    );

    const home = new CampaignRegistrationPage(student.page, lecture.id);
    await home.goto();
    const resolvedCard = await home.openCampaign("Resolved tutorial registration");
    const registerLabel = await home.registerButtons(resolvedCard).first()
      .getAttribute("aria-label");
    const resolvedTutorialTitle = registerLabel?.replace(/^Register for /, "") || "";
    expect(resolvedTutorialTitle).toBeTruthy();

    await home.register(resolvedCard);
    await expect(student.page.getByText("Registration completed successfully.")).toBeVisible();

    await home.goto();
    const additionalCard = await home.openCampaign("Additional tutorial registration");
    await home.register(additionalCard);
    await expect(student.page.getByText("Registration completed successfully.")).toBeVisible();

    await overriddenCampaign.__call("finalize!");
    await unrelatedCampaign.__call("finalize!");
    await home.goto();
    await expect(home.participation("Resolved tutorial registration")).toContainText("Rejected");
    await expect(home.participation("Additional tutorial registration")).toContainText("Rejected");

    await admitRejectedStudentThroughTeacherRoster(
      teacher.page,
      lecture.id,
      overriddenCampaign,
      resolvedTutorialTitle || "",
      student.user.email,
    );

    await home.goto();

    await expect(home.participation("Additional tutorial registration")).toContainText("Rejected");
    await expect(home.participation("Resolved tutorial registration")).toHaveCount(0);
    await expect(home.participation(resolvedTutorialTitle)).toContainText("Assigned");
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

    const home = new CampaignRegistrationPage(student.page, lecture.id);
    await home.goto();
    const fold = await home.openCampaign("Preference tutorial registration");

    const options = fold.getByTestId("registration-option");
    const firstOption = options.nth(0);
    const secondOption = options.nth(1);
    const thirdOption = options.nth(2);
    const preferencePodium = student.page.getByRole("group", {
      name: "Selected preference ranks",
    });
    const titleOf = async (option: typeof firstOption) => {
      const label = await option.getByRole("button", { name: /1st choice$/ })
        .getAttribute("aria-label");
      return label?.replace(/ as 1st choice$/, "") || "";
    };
    const firstTitle = await titleOf(firstOption);
    const secondTitle = await titleOf(secondOption);
    const thirdTitle = await titleOf(thirdOption);

    await expect(student.page.getByText("Rank 3 options.")).toBeVisible();
    const saveButton = student.page.getByRole("button", { name: "Save choices" });
    await expect(saveButton).toBeDisabled();
    await firstOption.getByRole("button", { name: /1st choice$/ }).click();
    expect(saveRequests).toBe(0);
    await expect(firstOption.getByRole("button", { name: /1st choice$/ }))
      .toHaveAttribute("aria-pressed", "true");
    await expect(preferencePodium).toContainText(firstTitle);
    await expect(fold.getByText("Unsaved changes").first()).toBeVisible();
    await expect(saveButton).toBeDisabled();
    await expect(student.page.getByTestId("preference-save-tooltip"))
      .toHaveAttribute("title", "Choose an option for every rank before saving.");

    await secondOption.getByRole("button", { name: /2nd choice$/ }).click();
    await thirdOption.getByRole("button", { name: /3rd choice$/ }).click();
    expect(saveRequests).toBe(0);
    await expect(saveButton).toBeEnabled();

    await thirdOption.getByRole("button", { name: /1st choice$/ }).click();

    await expect(thirdOption.getByRole("button", { name: /1st choice$/ }))
      .toHaveAttribute("aria-pressed", "true");
    await expect(secondOption.getByRole("button", { name: /2nd choice$/ }))
      .toHaveAttribute("aria-pressed", "true");
    await expect(firstOption.getByRole("button", { name: /3rd choice$/ }))
      .toHaveAttribute("aria-pressed", "true");
    await expect(student.page.getByRole("button", { pressed: true }))
      .toHaveCount(3);

    await saveButton.click();

    await expect(student.page.getByText("Your preferences have been saved.")).toBeVisible();
    await expect(saveButton).toBeDisabled();
    await expect(fold).toHaveAttribute("open", "");
    await expect(fold.locator("summary")).toContainText("Preferences saved");
    await expect(fold.locator("summary")).toContainText(`1st ${thirdTitle}`);
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

    const home = new CampaignRegistrationPage(student.page, lecture.id);
    await home.goto();
    const fold = await home.openCampaign("Two tutorial preference registration");

    const options = fold.getByTestId("registration-option");
    const preferencePodium = student.page.getByRole("group", {
      name: "Selected preference ranks",
    });

    await expect(student.page.getByText("Rank 2 options.")).toBeVisible();
    await expect(preferencePodium.getByTestId("preference-podium-spot")).toHaveCount(2);
    await expect(student.page.getByRole("button", { name: /3rd choice$/ })).toHaveCount(0);
    await expect(student.page.getByRole("button", { name: "Save choices" })).toBeDisabled();

    await options.nth(0).getByRole("button", { name: /1st choice$/ }).click();
    await options.nth(1).getByRole("button", { name: /2nd choice$/ }).click();
    await student.page.getByRole("button", { name: "Save choices" }).click();

    await expect(student.page.getByText("Your preferences have been saved.")).toBeVisible();
    expect(submittedBody).toContain("preferences%5B1%5D");
    expect(submittedBody).toContain("preferences%5B2%5D");
    expect(submittedBody).not.toContain("preferences%5B3%5D");
  });

  test("marks an open campaign the student has not registered in", async ({
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

    const home = new CampaignRegistrationPage(student.page, lecture.id);
    await home.goto();

    await expect(home.campaign("Tutorial registration")).toContainText("Not registered yet");
    await expect(student.page.getByRole("region", { name: "Your participation" }))
      .toHaveCount(0);
  });

  test("says in the campaign row which preferences are saved", async ({
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

    const home = new CampaignRegistrationPage(student.page, lecture.id);
    await home.goto();

    const row = home.campaign("Preference tutorial registration");
    await expect(row).toContainText("Preferences saved");
    await expect(row).toContainText("1st Pending Preference Tutorial");
    await expect(home.participation("Assigned")).toHaveCount(0);
  });

  test("shows an assignment next to a campaign that is still open", async ({
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

    const home = new CampaignRegistrationPage(student.page, lecture.id);
    await home.goto();

    await expect(home.participation("Assigned Tutorial")).toContainText("Assigned");
    await expect(home.campaign("Late tutorial registration")).toBeVisible();
  });

  test("blocks tutorial registration and self-enrollment for a join-only "
    + "assigned tutorial", async ({
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

    const home = new CampaignRegistrationPage(student.page, lecture.id);
    await home.goto();

    await expect(home.participation("Join-Only Assigned Tutorial")).toContainText("Assigned");
    // Another tutorial would mean leaving the one the student cannot leave,
    // through the campaign as much as through self-enrollment.
    const blockedTooltip
      = "You cannot join this tutorial since you cannot leave your tutorial. This was set up by your lecturer this way.";
    await expect(home.campaign("Late tutorial registration")).toContainText("Not available");
    await expect(student.page.getByRole("region", { name: "Registration open" }))
      .toHaveCount(0);
    const campaign = await home.openCampaign("Late tutorial registration");
    await expect(campaign.getByText(
      "You cannot register for another group because you cannot leave your current tutorial.",
    )).toBeVisible();
    await expect(home.registerButtons()).toHaveCount(0);
    await expect(campaign.getByRole("button", { name: "Unavailable" })).toHaveCount(3);
    const selfEnrollment = student.page.getByTestId("self-enrollment");
    await selfEnrollment.getByRole("heading", { name: "Join a group yourself" }).click();
    const alternativeOption = selfEnrollment.getByTestId("registration-option").filter({
      hasText: "Alternative Self Enrollment Tutorial",
    });
    await expect(alternativeOption).toContainText(blockedTooltip);

    const unavailableButton = alternativeOption.getByRole("button", { name: "Unavailable" });
    await expect(unavailableButton).toBeDisabled();
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

    const home = new CampaignRegistrationPage(student.page, lecture.id);
    await home.goto();

    await expect(home.participation("Early Morning Tutorial"))
      .toContainText("Your 2nd choice.");

    const home2 = new CampaignRegistrationPage(student2.page, lecture.id);
    await home2.goto();

    await expect(home2.participation("Fallback Tutorial"))
      .toContainText("Assigned outside your preferences.");
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

    await factory.create("registration_user_registration", ["capacity_rejected"], {
      user_id: student.user.id,
      registration_campaign_id: campaign.id,
      registration_item_id: item.id,
      preference_rank: 1,
    });
    await factory.create("registration_user_registration", ["capacity_rejected"], {
      user_id: student.user.id,
      registration_campaign_id: campaign.id,
      registration_item_id: secondPreferenceItem.id,
      preference_rank: 2,
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
    await factory.create("registration_user_registration", ["capacity_rejected"], {
      user_id: student.user.id,
      registration_campaign_id: secondCampaign.id,
      registration_item_id: secondItem.id,
      preference_rank: 1,
    });

    const home = new CampaignRegistrationPage(student.page, lecture.id);
    await home.goto();

    await expect(home.participation("No place")).toHaveCount(2);
    await expect(home.participation("Overbooked tutorial registration")).toContainText(
      "Your preferences: 1st Popular Tutorial, 2nd Early Morning Tutorial",
    );
    await expect(home.participation("Backup tutorial registration"))
      .toContainText("Your preferences: 1st Quiet Tutorial");
  });
});
