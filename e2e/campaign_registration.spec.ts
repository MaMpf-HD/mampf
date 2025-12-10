import { test, expect } from "./_support/fixtures";
import { CampaignRegistrationPage } from "./page-objects/campaign_registrations_page";

test.describe("draft campaign", () => {
  test("redirect and raise error if campaign is draft", async ({ factory, student }) => {
    const campaign = await factory.create("registration_campaign", ["for_lecture_enrollment"]);
    const page = new CampaignRegistrationPage(student.page, campaign.id);
    await page.goto();

    await expect(student.page.getByText("This campaign is not accessible right now.")).toBeVisible();
  });
});

test.describe("planning campaign", () => {
  test("redirect and raise error if campaign is draft", async ({ factory, student }) => {
    const campaign = await factory.create("registration_campaign", ["for_lecture_enrollment", "open", "planning_only"]);
    const page = new CampaignRegistrationPage(student.page, campaign.id);
    await page.goto();

    await expect(student.page.getByText("Planning")).toBeVisible();
  });
});

test.describe("processing campaign", () => {
  test("should render campaign but not allow to interact, lecture campaign", async ({ factory, student }) => {
    const campaign = await factory.create("registration_campaign", ["for_lecture_enrollment", "processing"]);
    const page = new CampaignRegistrationPage(student.page, campaign.id);
    await page.goto();

    await expect(student.page.getByText("Processing")).toBeVisible();
    await expect(student.page.getByRole("button", { name: "Register now" })).toBeDisabled();
  });

  test("should render campaign but not allow to interact, tutorial campaign", async ({ factory, student }) => {
    const campaign = await factory.create("registration_campaign", ["processing", "for_tutorial_enrollment"]);
    const page = new CampaignRegistrationPage(student.page, campaign.id);
    await page.goto();

    await expect(student.page.getByText("Processing")).toBeVisible();
    const buttons = student.page.locator('button:has-text("Register now")');
    await expect(buttons.nth(0)).toBeDisabled();
    await expect(buttons.nth(1)).toBeDisabled();
  });
});

test.describe("completed campaign", () => {
  test("should render campaign but not allow to interact, lecture campaign", async ({ factory, student }) => {
    const campaign = await factory.create("registration_campaign", ["for_lecture_enrollment", "processing"]);
    const page = new CampaignRegistrationPage(student.page, campaign.id);
    await page.goto();

    await expect(student.page.getByText("Processing")).toBeVisible();
    await expect(student.page.getByRole("button", { name: "Register now" })).toBeDisabled();
  });

  test("should render campaign but not allow to interact, tutorial campaign", async ({ factory, student }) => {
    const campaign = await factory.create("registration_campaign", ["processing", "for_tutorial_enrollment"]);
    const page = new CampaignRegistrationPage(student.page, campaign.id);
    await page.goto();

    await expect(student.page.getByText("Processing")).toBeVisible();
    const buttons = student.page.locator('button:has-text("Register now")');
    await expect(buttons.nth(0)).toBeDisabled();
    await expect(buttons.nth(1)).toBeDisabled();
  });
});

test.describe("closed campaign", () => {
  test("should render campaign but not allow to interact, lecture campaign", async ({ factory, student }) => {
    const campaign = await factory.create("registration_campaign", ["for_lecture_enrollment", "closed"]);
    const page = new CampaignRegistrationPage(student.page, campaign.id);
    await page.goto();

    await expect(student.page.getByText("Closed")).toBeVisible();
    await expect(student.page.getByRole("button", { name: "Register now" })).toBeDisabled();
  });

  test("should render campaign but not allow to interact, tutorial campaign", async ({ factory, student }) => {
    const campaign = await factory.create("registration_campaign", ["closed", "for_tutorial_enrollment"]);
    const page = new CampaignRegistrationPage(student.page, campaign.id);
    await page.goto();

    await expect(student.page.getByText("Closed")).toBeVisible();
    const buttons = student.page.locator('button:has-text("Register now")');
    await expect(buttons.nth(0)).toBeDisabled();
    await expect(buttons.nth(1)).toBeDisabled();
  });
});

test.describe("open lecture campaign", () => {
  test.describe("register open lecture campaign", () => {
    test("creates a confirmed registration when validations pass, case no user registration", async ({ factory, student }) => {
      const campaign = await factory.create("registration_campaign", ["open", "for_lecture_enrollment"]);
      const page = new CampaignRegistrationPage(student.page, campaign.id);
      await page.goto();

      await page.register();
      await expect(student.page.getByText(/\/100 filled/)).toContainText("1/100");
      await expect(student.page.getByText("Open")).toBeVisible();
    });

    test("cannot click register button if item has no capacity", async ({ factory, student }) => {
      const campaign = await factory.create("registration_campaign", ["open", "for_lecture_enrollment", "no_capacity_remained_first_item"]);
      const page = new CampaignRegistrationPage(student.page, campaign.id);
      await page.goto();
      await expect(student.page.getByRole("button", { name: "Register now" }).nth(0)).toBeDisabled();
    });
  });

  test.describe("withdraw open lecture campaign", () => {
    test("updates to rejected registration when validations pass", async ({ factory, student }) => {
      const campaign = await factory.create("registration_campaign", ["open", "for_lecture_enrollment"]);
      const page = new CampaignRegistrationPage(student.page, campaign.id);
      await page.goto();

      await page.register();
      await expect(student.page.getByRole("button", { name: "Withdraw" })).toBeEnabled();
      await page.withdraw();
      await expect(student.page.getByText(/\/100 filled/)).toContainText("0/100");
      await expect(student.page.getByRole("button", { name: "Register now" })).toBeEnabled();
    });
  });
});

test.describe("open tutorial campaign", () => {
  test.describe("register open tutorial campaign", () => {
    test("creates a confirmed registration when validations pass", async ({ factory, student }) => {
      const campaign = await factory.create("registration_campaign", ["open", "for_tutorial_enrollment"]);
      const page = new CampaignRegistrationPage(student.page, campaign.id);
      await page.goto();

      await expect(student.page.getByText(/\/200 filled/)).toContainText("0/200");
      let buttons = student.page.locator('button:has-text("Register now")');
      await expect(buttons).toHaveCount(2);
      await expect(buttons.nth(0)).toBeEnabled();
      await expect(buttons.nth(1)).toBeEnabled();

      await student.page.getByRole("button", { name: "Register now" }).nth(0).click();

      buttons = student.page.locator('button:has-text("Register now")');
      await expect(buttons).toHaveCount(0);
      buttons = student.page.locator('button:has-text("Withdraw")');
      await expect(buttons).toHaveCount(1);

      await expect(student.page.getByText(/\/200 filled/)).toContainText("1/200");
    });

    test("cannot click register button if item has no capacity", async ({ factory, student }) => {
      const campaign = await factory.create("registration_campaign", ["open", "for_tutorial_enrollment", "no_capacity_remained_first_item"]);
      const page = new CampaignRegistrationPage(student.page, campaign.id);
      await page.goto();
      const buttons = student.page.locator('button:has-text("Register now")');
      await expect(buttons.nth(0)).toBeDisabled();
      await expect(buttons.nth(1)).toBeEnabled();
    });
  });

  test.describe("withdraw open tutorial campaign", () => {
    test("updates to rejected registration when validations pass", async ({ factory, student }) => {
      const campaign = await factory.create("registration_campaign", ["open", "for_tutorial_enrollment"]);
      const page = new CampaignRegistrationPage(student.page, campaign.id);
      await page.goto();

      await student.page.getByRole("button", { name: "Register now" }).nth(0).click();
      await page.withdraw();
      await expect(student.page.getByText(/\/200 filled/)).toContainText("0/200");
    });
  });
});

test.describe("integration between child and parent campaign", () => {
  test("expect page of child campaign to have link to parent campaign", async ({ factory, student }) => {
    const parent = await factory.create("registration_campaign", ["open", "for_lecture_enrollment"]);
    const child = await factory.create("registration_campaign", ["open", "for_tutorial_enrollment", "with_prerequisite_policy"], { parent_campaign_id: parent.id });
    const page = new CampaignRegistrationPage(student.page, child.id);
    await page.goto();
    const link = student.page.getByRole("link", { name: "Prerequisite Campaign" });
    await expect(link).toHaveAttribute("href", `/campaign_registrations/${parent.id}`);
  });

  test("cannot register child if parent has not been registered", async ({ factory, student }) => {
    const parent = await factory.create("registration_campaign", ["open", "for_lecture_enrollment"]);
    const child = await factory.create("registration_campaign", ["open", "for_tutorial_enrollment", "with_prerequisite_policy"], { parent_campaign_id: parent.id });
    const page = new CampaignRegistrationPage(student.page, child.id);
    await page.goto();
    await student.page.getByRole("button", { name: "Register now" }).nth(0).click();
    await expect(student.page.getByText("You do not meet the requirements.")).toBeVisible();
  });

  test("cannot withdraw parent if child has been registered", async ({ factory, student }) => {
    const parent = await factory.create("registration_campaign", ["open", "for_lecture_enrollment"]);
    const child = await factory.create("registration_campaign", ["open", "for_tutorial_enrollment", "with_prerequisite_policy"], { parent_campaign_id: parent.id });

    // Register parent -> child
    const parentPage = new CampaignRegistrationPage(student.page, parent.id);
    await parentPage.goto();
    await student.page.getByRole("button", { name: "Register now" }).nth(0).click();
    let childPage = new CampaignRegistrationPage(student.page, child.id);
    await childPage.goto();
    await student.page.getByRole("button", { name: "Register now" }).nth(0).click();

    // Try to withdraw child
    childPage = new CampaignRegistrationPage(student.page, child.id);
    await parentPage.goto();
    await parentPage.withdraw();
    await expect(student.page.getByText(/Withdrawal is blocked because the following campaigns are confirmed/i)).toBeVisible();
  });
});
