import { enableFeature } from "./_support/backend";
import { expect, test } from "./_support/fixtures";

test.describe("lecture group registration sections", () => {
  test.beforeEach(async ({ request }) => {
    await enableFeature(request, "roster_maintenance");
    await enableFeature(request, "registration_campaigns");
  });

  test("collapses the registration process area when ambient tutorials exist",
    async ({ factory, teacher: { page, user } }) => {
      const lecture = await factory.create("lecture", [], { teacher_id: user.id });
      await factory.create("tutorial", [], {
        lecture_id: lecture.id,
        title: "Tuesday Tutorial",
      });

      await page.goto(`/lectures/${lecture.id}/edit?tab=groups`);

      const campaignSection = page.getByTestId("registration-campaign-section");
      await expect(campaignSection).toBeVisible();
      await expect(page.getByText("Tuesday Tutorial")).toBeVisible();

      await expect(
        campaignSection.getByRole("button", { name: "Registration Process" }),
      ).toHaveAttribute("aria-expanded", "false");
      await expect(
        campaignSection.getByTestId("registration-campaign-section-body"),
      ).not.toBeVisible();
    });

  test("collapses the ambient area when a campaign already owns all tutorials",
    async ({ factory, teacher: { page, user } }) => {
      const lecture = await factory.create("lecture", [], { teacher_id: user.id });
      await factory.create("registration_campaign", ["open", "first_come_first_served"], {
        campaignable_type: "Lecture",
        campaignable_id: lecture.id,
        description: "Tutorial registration",
        items_count: 1,
      });

      await page.goto(`/lectures/${lecture.id}/edit?tab=groups`);

      const noCampaignSection = page.getByTestId("registration-no-campaign-section");
      await expect(noCampaignSection).toBeVisible();
      await expect(page.getByText("Tutorial registration")).toBeVisible();

      await expect(
        noCampaignSection.getByRole("button", { name: "Without Registration Process" }),
      ).toHaveAttribute("aria-expanded", "false");
      await expect(
        noCampaignSection.getByTestId("registration-no-campaign-section-body"),
      ).not.toBeVisible();
    });
});
