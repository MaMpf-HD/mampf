import { test, expect } from "./_support/fixtures";
import { CampaignRegistrationPage } from "./page-objects/campaign_registrations_page";

test.describe("register lecture campaign", () => {
  test("creates a confirmed registration when validations pass, case no user registration", async ({ factory, student }) => {
    const campaign = await factory.create("registration_campaign", ["open", "for_lecture_enrollment"]);
    const page = new CampaignRegistrationPage(student.page, campaign.id);
    await page.goto();

    await page.register();
    await expect(student.page.getByText(/Seats 1\/100/)).toBeVisible();
  });

  test("raises error if campaign is draft", async ({ factory, student }) => {
    const campaign = await factory.create("registration_campaign", ["for_lecture_enrollment"]);
    await campaign.__call("update!");

    const page = new CampaignRegistrationPage(student.page, campaign.id);
    await page.goto();

    await expect(page.register()).rejects.toThrow();
  });

  test("raises error if item has no capacity", async ({ factory, student }) => {
    const campaign = await factory.create("registration_campaign", ["open", "for_lecture_enrollment"]);
    const item = campaign.registration_items[0];
    await item.registerable.__call("update!", { capacity: 0 });

    const page = new CampaignRegistrationPage(student.page, campaign.id);
    await page.goto();

    await expect(page.register()).rejects.toThrow();
  });
});

test.describe("withdraw lecture campaign", () => {
  test("updates to rejected registration when validations pass", async ({ factory, student }) => {
    const campaign = await factory.create("registration_campaign", ["open", "for_lecture_enrollment"]);
    const page = new CampaignRegistrationPage(student.page, campaign.id);
    await page.goto();

    await page.register();
    await page.withdraw();
    await expect(student.page.getByText(/Seats 0\/100/)).toBeVisible();
  });
});

test.describe("register tutorial campaign", () => {
  test("creates a confirmed registration when validations pass", async ({ factory, student }) => {
    const campaign = await factory.create("registration_campaign", ["open", "for_tutorial_enrollment"]);
    const page = new CampaignRegistrationPage(student.page, campaign.id);
    await page.goto();

    await page.register();
    await expect(student.page.getByText(/Seats 1\/100/)).toBeVisible();
  });

  test("raises error if user already registered for another item", async ({ factory, student }) => {
    const campaign = await factory.create("registration_campaign", ["open", "for_tutorial_enrollment"]);
    const item2 = campaign.registration_items[1];
    await factory.create("user_registration", [], {
      registration_campaign_id: campaign.id,
      registration_item_id: item2.id,
      user_id: student.user.id,
      status: "confirmed",
    });

    const page = new CampaignRegistrationPage(student.page, campaign.id);
    await page.goto();

    await expect(page.register()).rejects.toThrow();
  });
});

test.describe("withdraw tutorial campaign", () => {
  test("updates to rejected registration when validations pass", async ({ factory, student }) => {
    const campaign = await factory.create("registration_campaign", ["open", "for_tutorial_enrollment"]);
    const page = new CampaignRegistrationPage(student.page, campaign.id);
    await page.goto();

    await page.register();
    await page.withdraw();
    await expect(student.page.getByText(/Seats 0\/100/)).toBeVisible();
  });
});
