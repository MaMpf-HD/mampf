import { test, expect } from "./_support/fixtures";
import { CampaignRegistrationPage } from "./page-objects/campaign_registrations_page";

test.describe("draft campaign", () => {
  test("given draft campaign, when user visits, then access error is shown", async ({ factory, student }) => {
    const campaign = await factory.create("registration_campaign", ["first_come_first_served"]);
    const page = new CampaignRegistrationPage(student.page, campaign.id);
    await page.goto();
    await expect(student.page.getByText("This campaign is not accessible right now.")).toBeVisible();
  });
});

test.describe("planning campaign", () => {
  test("given planning campaign, when user visits, then planning badge is shown", async ({ factory, student }) => {
    const campaign = await factory.create("registration_campaign", ["open", "planning_only"], { self_registerable: true });
    const page = new CampaignRegistrationPage(student.page, campaign.id);
    await page.goto();
    await expect(student.page.getByText("Planning")).toBeVisible();
  });
});

test.describe("given processing lecture campaign", () => {
  test("when user visits, then register button is disabled, lecture campaign", async ({ factory, student }) => {
    const campaign = await factory.create("registration_campaign", ["processing"], { self_registerable: true });
    const page = new CampaignRegistrationPage(student.page, campaign.id);
    await page.goto();
    await expect(student.page.getByText("Processing")).toBeVisible();
    await expect(student.page.getByRole("button", { name: "Register now" })).toBeDisabled();
  });

  test("when user visits, then register button is disabled, tutorial campaign", async ({ factory, student }) => {
    const campaign = await factory.create("registration_campaign", ["processing"]);
    const page = new CampaignRegistrationPage(student.page, campaign.id);
    await page.goto();
    await expect(student.page.getByText("Processing")).toBeVisible();
    const buttons = student.page.locator('button:has-text("Register now")');
    await expect(buttons.nth(0)).toBeDisabled();
    await expect(buttons.nth(1)).toBeDisabled();
  });
});

test.describe("given completed campaign", () => {
  test("without roster result, when user visits, then dismissed status is shown", async ({ factory, student }) => {
    const campaign = await factory.create("registration_campaign", ["completed", "with_items"]);
    const page = new CampaignRegistrationPage(student.page, campaign.id);
    await page.goto();
    await expect(student.page.getByText("Completed")).toBeVisible();
    await expect(student.page.getByText("Dismissed")).toBeVisible();
  });

  test("with roster result, when user visits, then assigned status is shown", async ({ factory, student }) => {
    const campaign = await factory.create("registration_campaign", ["completed", "with_items", "with_first_item_registered", "with_first_item_allocated"], { user_id: student["user"]["id"] });
    const page = new CampaignRegistrationPage(student.page, campaign.id);
    await page.goto();
    await expect(student.page.getByText("Completed")).toBeVisible();
    await expect(student.page.getByText("Assigned")).toBeVisible();
  });
});

test.describe("given completed campaign, preference based", () => {
  test("without roster result, when user visits, then dismissed status is shown", async ({ factory, student }) => {
    const campaign = await factory.create("registration_campaign", ["completed", "preference_based", "with_items"]);
    const page = new CampaignRegistrationPage(student.page, campaign.id);
    await page.goto();
    await expect(student.page.getByText("Completed")).toBeVisible();
    await expect(student.page.getByText("Dismissed")).toBeVisible();
  });

  test("with roster result, when user visits, then assigned status is shown", async ({ factory, student }) => {
    const campaign = await factory.create("registration_campaign", ["completed", "preference_based", "with_items", "with_first_item_registered_preference", "with_first_item_allocated"], { user_id: student["user"]["id"] });
    const page = new CampaignRegistrationPage(student.page, campaign.id);
    await page.goto();
    await expect(student.page.getByText("Completed")).toBeVisible();
    await expect(student.page.getByText("Assigned")).toBeVisible();
  });
});

test.describe("closed campaign", () => {
  test("should render campaign but not allow to interact, lecture campaign", async ({ factory, student }) => {
    const campaign = await factory.create("registration_campaign", ["closed"], { self_registerable: true });
    const page = new CampaignRegistrationPage(student.page, campaign.id);
    await page.goto();
    await expect(student.page.getByText("Closed")).toBeVisible();
    await expect(student.page.getByRole("button", { name: "Register now" })).toBeDisabled();
  });

  test("should render campaign but not allow to interact, tutorial campaign", async ({ factory, student }) => {
    const campaign = await factory.create("registration_campaign", ["closed"]);
    const page = new CampaignRegistrationPage(student.page, campaign.id);
    await page.goto();

    await expect(student.page.getByText("Closed")).toBeVisible();
    const buttons = student.page.locator('button:has-text("Register now")');
    await expect(buttons.nth(0)).toBeDisabled();
    await expect(buttons.nth(1)).toBeDisabled();
  });
});

test.describe("given open campaign, lecture campaign", () => {
  test.describe("register open lecture campaign", () => {
    test("creates a confirmed registration when validations pass, case no user registration", async ({ factory, student }) => {
      const campaign = await factory.create("registration_campaign", ["open"], { self_registerable: true });
      const page = new CampaignRegistrationPage(student.page, campaign.id);
      await page.goto();

      await page.register();
      await expect(student.page.getByText("/ 100 filled")).toContainText("1 / 100");
      await expect(student.page.getByText("Open")).toBeVisible();
    });

    test("with full item, when user visits, then register button is disabled", async ({ factory, student }) => {
      const campaign = await factory.create("registration_campaign", ["open", "no_capacity_remained_first_item"], { self_registerable: true });
      const page = new CampaignRegistrationPage(student.page, campaign.id);
      await page.goto();
      await expect(student.page.getByRole("button", { name: "Register now" }).nth(0)).toBeDisabled();
    });
  });

  test.describe("withdraw open lecture campaign", () => {
    test("with registration, when user withdraws, then status updates to rejected", async ({ factory, student }) => {
      const campaign = await factory.create("registration_campaign", ["open"], { self_registerable: true });
      const page = new CampaignRegistrationPage(student.page, campaign.id);
      await page.goto();

      await page.register();
      await expect(student.page.getByRole("button", { name: "Withdraw" })).toBeEnabled();
      await page.withdraw();
      await expect(student.page.getByText("/ 100 filled")).toContainText("0 / 100");
      await expect(student.page.getByRole("button", { name: "Register now" })).toBeEnabled();
    });
  });
});

test.describe("open fcfs tutorial campaign", () => {
  test.describe("register open tutorial campaign", () => {
    test("creates a confirmed registration when validations pass", async ({ factory, student }) => {
      const campaign = await factory.create("registration_campaign", ["open", "first_come_first_served"], { capacity: 100 });
      const page = new CampaignRegistrationPage(student.page, campaign.id);
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
      const campaign = await factory.create("registration_campaign", ["open", "no_capacity_remained_first_item", "first_come_first_served"], { capacity: 100 });
      const page = new CampaignRegistrationPage(student.page, campaign.id);
      await page.goto();
      const buttons = student.page.locator('button:has-text("Register now")');
      await buttons.nth(0).isDisabled();
      await buttons.nth(1).isEnabled();
    });
  });

  test.describe("withdraw open tutorial campaign", () => {
    test("when user withdraws, then status updates to rejected", async ({ factory, student }) => {
      const campaign = await factory.create("registration_campaign", ["open", "first_come_first_served"], { capacity: 100 });
      const page = new CampaignRegistrationPage(student.page, campaign.id);
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
      const campaign = await factory.create("registration_campaign", ["open", "preference_based"], { capacity: 100 });
      const page = new CampaignRegistrationPage(student.page, campaign.id);
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
      let ranklist = student.page.getByText("Rank:");
      await expect(ranklist).toHaveCount(2);
      await expect(student.page.getByText("You have unsaved changes.")).toBeVisible();

      // save should refresh page and selected list should be displayed
      const saveButton = student.page.locator('button:has-text("Save")');
      await Promise.all([
        student.page.waitForURL("**/campaign_registrations/**"),
        saveButton.click(),
      ]);
      ranklist = student.page.getByText("Rank:");
      await expect(ranklist).toHaveCount(2);

      // up action should move content up
      let items = student.page.locator(".row.m-2");
      const titleBefore1 = await items.nth(0).locator(".col-9").innerText();
      const titleBefore2 = await items.nth(1).locator(".col-9").innerText();
      await Promise.all([
        student.page.waitForLoadState("networkidle"),
        items.nth(1).locator("button.arrow_upward").dispatchEvent("click"),
      ]);
      items = student.page.locator(".row.m-2");
      const titleAfter1 = await items.nth(0).locator(".col-9").innerText();
      const titleAfter2 = await items.nth(1).locator(".col-9").innerText();
      expect(titleBefore1[0]).toBe(titleAfter2[0]);
      expect(titleBefore2[0]).toBe(titleAfter1[0]);

      // remove action should remove content from list
      await Promise.all([
        student.page.waitForLoadState("networkidle"),
        student.page.locator(".row.m-2").nth(1).locator("button.playlist_remove").click(),
      ]);
      ranklist = student.page.getByText("Rank:");
      await expect(ranklist).toHaveCount(1);
    });
  });
});

test.describe("integration between child and parent campaign", () => {
  test("given child campaign with prerequisite, when user visits, then link to parent is shown", async ({ factory, student }) => {
    const parent = await factory.create("registration_campaign", ["open"], { self_registerable: true });
    const child = await factory.create("registration_campaign", ["open", "with_prerequisite_policy"], { parent_campaign_id: parent.id });
    const page = new CampaignRegistrationPage(student.page, child.id);
    await page.goto();
    const link = student.page.getByRole("link", { name: "Prerequisite Campaign" });
    await expect(link).toHaveAttribute("href", `/campaign_registrations/${parent.id}`);
  });

  test("given child campaign with prerequisite, when parent not registered, then registration is blocked", async ({ factory, student }) => {
    const parent = await factory.create("registration_campaign", ["open"], { self_registerable: true });
    const child = await factory.create("registration_campaign", ["open", "with_prerequisite_policy"], { parent_campaign_id: parent.id });
    const page = new CampaignRegistrationPage(student.page, child.id);
    await page.goto();
    await student.page.getByRole("button", { name: "Register now" }).nth(0).click();
    await expect(student.page.getByText("You do not meet the requirements.")).toBeVisible();
  });

  test("given parent campaign with registered child, when user withdraws parent, then withdrawal is blocked", async ({ factory, student }) => {
    const parent = await factory.create("registration_campaign", ["open"], { self_registerable: true });
    const child = await factory.create("registration_campaign", ["open", "with_prerequisite_policy"], { parent_campaign_id: parent.id });

    // Register parent -> child
    const parentPage = new CampaignRegistrationPage(student.page, parent.id);
    await parentPage.goto();
    await student.page.getByRole("button", { name: "Register now" }).nth(0).click();
    const childPage = new CampaignRegistrationPage(student.page, child.id);
    await childPage.goto();
    await student.page.getByRole("button", { name: "Register now" }).nth(0).click();

    // Try to withdraw parent
    await parentPage.goto();
    await parentPage.withdraw();
    await expect(student.page.getByText("Withdrawal is blocked")).toBeVisible();
  });
});
