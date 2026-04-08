import { test, expect } from "./_support/fixtures";
import { CampaignRegistrationPage } from "./page-objects/campaign_registrations_page";
import { LecturePage } from "./page-objects/lecture_page";

test.describe("given completed campaign", () => {
  test("without roster result, when user visits, then dismissed status is shown",
    async ({ factory, student }) => {
      const calculusCourse = await factory.create("course", [], { title: "Advanced Calculus" });
      const lecture = await factory.create("lecture", ["released_for_all"], { course_id: calculusCourse.id });
      const lecturePage = new LecturePage(student.page, lecture.id);
      await lecturePage.goto();
      const campaign = await factory.create("registration_campaign",
        ["completed", "with_items"],
        { campaignable_type: "Lecture", campaignable_id: lecture.id });

      const registrationLink = student.page.getByRole("button", { name: "Subscribe event series" });
      await expect(registrationLink).toBeVisible();
      await registrationLink.click();
      const page = new CampaignRegistrationPage(student.page, lecture.id);
      await page.goto();
      const completedSection = student.page.getByText("Abgeschlossene Kampagnen")
        .or(student.page.getByText("Completed Campaign"));
      await expect(completedSection).toBeVisible();
      await completedSection.click();
      await expect(student.page.getByText("Completed", { exact: true })).toBeVisible();
      await expect(student.page.getByText("Dismissed")).toBeVisible();
    });

  test("with roster result, when user visits, then assigned status is shown", async ({ factory, student }) => {
    const calculusCourse = await factory.create("course", [], { title: "Advanced Calculus" });
    const lecture = await factory.create("lecture", ["released_for_all"], { course_id: calculusCourse.id });
    const lecturePage = new LecturePage(student.page, lecture.id);
    await lecturePage.goto();
    const registrationLink = student.page.getByRole("button", { name: "Subscribe event series" });
    await expect(registrationLink).toBeVisible();
    await registrationLink.click();
    const campaign = await factory.create("registration_campaign",
      ["completed", "with_items", "with_first_item_registered", "with_first_item_allocated"],
      { user_id: student["user"]["id"], campaignable_type: "Lecture", campaignable_id: lecture.id });
    const page = new CampaignRegistrationPage(student.page, lecture.id);
    await page.goto();
    const completedSection = student.page.getByText("Abgeschlossene Kampagnen")
      .or(student.page.getByText("Completed Campaign"));
    await expect(completedSection).toBeVisible();
    await completedSection.click();
    await expect(student.page.getByText("Completed", { exact: true })).toBeVisible();
    await expect(student.page.getByText("Assigned")).toBeVisible();
  });
});

test.describe("given completed campaign, preference based", () => {
  test("without roster result, when user visits, then dismissed status is shown", async ({ factory, student }) => {
    const calculusCourse = await factory.create("course", [], { title: "Advanced Calculus" });
    const lecture = await factory.create("lecture", ["released_for_all"], { course_id: calculusCourse.id });
    const lecturePage = new LecturePage(student.page, lecture.id);
    await lecturePage.goto();
    const registrationLink = student.page.getByRole("button", { name: "Subscribe event series" });
    await expect(registrationLink).toBeVisible();
    await registrationLink.click();
    const campaign = await factory.create("registration_campaign", ["completed", "preference_based", "with_items"], { campaignable_type: "Lecture", campaignable_id: lecture.id });
    const page = new CampaignRegistrationPage(student.page, lecture.id);
    await page.goto();
    const completedSection = student.page.getByText("Abgeschlossene Kampagnen")
      .or(student.page.getByText("Completed Campaign"));
    await expect(completedSection).toBeVisible();
    await completedSection.click();
    await expect(student.page.getByText("Completed", { exact: true })).toBeVisible();
    await expect(student.page.getByText("Dismissed")).toBeVisible();
  });

  test("with roster result, when user visits, then assigned status is shown", async ({ factory, student }) => {
    const calculusCourse = await factory.create("course", [], { title: "Advanced Calculus" });
    const lecture = await factory.create("lecture", ["released_for_all"], { course_id: calculusCourse.id });
    const lecturePage = new LecturePage(student.page, lecture.id);
    await lecturePage.goto();
    const registrationLink = student.page.getByRole("button", { name: "Subscribe event series" });
    await expect(registrationLink).toBeVisible();
    await registrationLink.click();
    const campaign = await factory.create("registration_campaign", ["completed", "preference_based", "with_items", "with_first_item_registered_preference", "with_first_item_allocated"], { user_id: student["user"]["id"], campaignable_type: "Lecture", campaignable_id: lecture.id });
    const page = new CampaignRegistrationPage(student.page, lecture.id);
    await page.goto();
    const completedSection = student.page.getByText("Abgeschlossene Kampagnen")
      .or(student.page.getByText("Completed Campaign"));
    await expect(completedSection).toBeVisible();
    await completedSection.click();
    await expect(student.page.getByText("Completed", { exact: true })).toBeVisible();
    await expect(student.page.getByText("Assigned")).toBeVisible();
  });
});

test.describe("closed campaign", () => {
  test("should render campaign but not allow to interact, tutorial campaign", async ({ factory, student }) => {
    const calculusCourse = await factory.create("course", [], { title: "Advanced Calculus" });
    const lecture = await factory.create("lecture", ["released_for_all"], { course_id: calculusCourse.id });
    const lecturePage = new LecturePage(student.page, lecture.id);
    await lecturePage.goto();
    const registrationLink = student.page.getByRole("button", { name: "Subscribe event series" });
    await expect(registrationLink).toBeVisible();
    await registrationLink.click();
    const campaign = await factory.create("registration_campaign", ["closed"], { campaignable_type: "Lecture", campaignable_id: lecture.id });
    const page = new CampaignRegistrationPage(student.page, lecture.id);
    await page.goto();
    const completedSection = student.page.getByText("Abgeschlossene Kampagnen")
      .or(student.page.getByText("Completed Campaign"));
    await expect(completedSection).toBeVisible();
    await completedSection.click();
    await expect(student.page.getByText("Closed")).toBeVisible();
    const buttons = student.page.locator('button:has-text("Register now")');
    await expect(buttons.nth(0)).toBeDisabled();
    await expect(buttons.nth(1)).toBeDisabled();
  });
});

test.describe("open fcfs tutorial campaign", () => {
  test.describe("register open tutorial campaign", () => {
    test("creates a confirmed registration when validations pass", async ({ factory, student }) => {
      const calculusCourse = await factory.create("course", [], { title: "Advanced Calculus" });
      const lecture = await factory.create("lecture", ["released_for_all"], { course_id: calculusCourse.id });
      const lecturePage = new LecturePage(student.page, lecture.id);
      await lecturePage.goto();
      const registrationLink = student.page.getByRole("button", { name: "Subscribe event series" });
      await expect(registrationLink).toBeVisible();
      await registrationLink.click();
      const campaign = await factory.create("registration_campaign", ["open", "first_come_first_served"], { capacity: 100, campaignable_type: "Lecture", campaignable_id: lecture.id });
      const page = new CampaignRegistrationPage(student.page, lecture.id);
      await page.goto();

      await expect(student.page.getByText("/ 300 filled")).toContainText("0 / 300");
      let buttons = student.page.locator('button:has-text("Register now")');
      await expect(buttons).toHaveCount(3);
      await expect(buttons.nth(0)).toBeEnabled();
      await expect(buttons.nth(1)).toBeEnabled();

      await student.page.getByRole("button", { name: "Register now" }).nth(0).click();

      buttons = student.page.locator('button:has-text("Register now")');
      await expect(buttons).toHaveCount(0);
      buttons = student.page.locator('button:has-text("Withdraw")');
      await expect(buttons).toHaveCount(1);

      await expect(student.page.getByText("/ 300 filled")).toContainText("1 / 300");
    });

    test("with full item, when user visits, then register button is disabled", async ({ factory, student }) => {
      const calculusCourse = await factory.create("course", [], { title: "Advanced Calculus" });
      const lecture = await factory.create("lecture", ["released_for_all"], { course_id: calculusCourse.id });
      const lecturePage = new LecturePage(student.page, lecture.id);
      await lecturePage.goto();
      const registrationLink = student.page.getByRole("button", { name: "Subscribe event series" });
      await expect(registrationLink).toBeVisible();
      await registrationLink.click();
      const campaign = await factory.create("registration_campaign", ["open", "no_remaining_capacity_first_item", "first_come_first_served"], { capacity: 100, campaignable_type: "Lecture", campaignable_id: lecture.id });
      const page = new CampaignRegistrationPage(student.page, lecture.id);
      await page.goto();
      const buttons = student.page.locator('button:has-text("Register now"):disabled');
      await expect(buttons).toHaveCount(1);
    });
  });

  test.describe("withdraw open tutorial campaign", () => {
    test("when user withdraws, then status updates to rejected", async ({ factory, student }) => {
      const calculusCourse = await factory.create("course", [], { title: "Advanced Calculus" });
      const lecture = await factory.create("lecture", ["released_for_all"], { course_id: calculusCourse.id });
      const lecturePage = new LecturePage(student.page, lecture.id);
      await lecturePage.goto();
      const registrationLink = student.page.getByRole("button", { name: "Subscribe event series" });
      await expect(registrationLink).toBeVisible();
      await registrationLink.click();
      const campaign = await factory.create("registration_campaign", ["open", "first_come_first_served"], { capacity: 100, campaignable_type: "Lecture", campaignable_id: lecture.id });
      const page = new CampaignRegistrationPage(student.page, lecture.id);
      await page.goto();
      await student.page.getByRole("button", { name: "Register now" }).nth(0).click();
      await page.withdraw();
      await expect(student.page.getByText("/ 300 filled")).toContainText("0 / 300");
    });
  });
});

test.describe("open preference based tutorial campaign", () => {
  test.describe("register open tutorial campaign", () => {
    test("creates pending registrations when validations pass", async ({ factory, student }) => {
      const calculusCourse = await factory.create("course", [], { title: "Advanced Calculus" });
      const lecture = await factory.create("lecture", ["released_for_all"], { course_id: calculusCourse.id });
      const lecturePage = new LecturePage(student.page, lecture.id);
      await lecturePage.goto();
      const registrationLink = student.page.getByRole("button", { name: "Subscribe event series" });
      await expect(registrationLink).toBeVisible();
      await registrationLink.click();
      const campaign = await factory.create("registration_campaign", ["open", "preference_based"], { capacity: 100, campaignable_type: "Lecture", campaignable_id: lecture.id });
      const page = new CampaignRegistrationPage(student.page, lecture.id);
      await page.goto();

      // be possible to add items to preferences list
      const buttons = student.page.locator('button:has-text("playlist_add")');
      await expect(buttons).toHaveCount(3);
      await expect(buttons.nth(0)).toBeEnabled();
      await expect(buttons.nth(1)).toBeEnabled();
      await expect(buttons.nth(2)).toBeEnabled();

      // add first 2 options to list, added options cannot be readd
      await buttons.nth(0).click();
      await expect(buttons.nth(0)).toBeDisabled();
      await buttons.nth(1).click();
      await expect(buttons.nth(1)).toBeDisabled();

      // rank list should be updated
      let ranklist = student.page.getByText("Rank:").or(student.page.getByText("Rang:"));
      await expect(ranklist).toHaveCount(2);
      await expect(student.page.getByText("You have unsaved changes.")
        .or(student.page.getByText("Sie haben ungespeicherte Änderungen.")))
        .toBeVisible();

      // save should refresh page and selected list should be displayed
      const saveButton = student.page.locator('button:has-text("Save")');
      ranklist = student.page.getByText("Rank:").or(student.page.getByText("Rang:"));
      await expect(ranklist).toHaveCount(2);

      // up action should move content up

      // remove action should remove content from list
    });
  });
});
