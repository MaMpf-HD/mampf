import { expect, test } from "./_support/fixtures";

test.describe("the registered view of the participants tab", () => {
  test("finds a registered student who is not on the participants list yet",
    async ({ factory, teacher: { page, user } }) => {
      const lecture = await factory.create("lecture", [], { teacher_id: user.id });
      const campaign = await factory.create("registration_campaign", ["first_come_first_served"], {
        campaignable_type: "Lecture", campaignable_id: lecture.id,
        description: "Tutorial registration",
      });
      const tutorial = await factory.create("tutorial", [], {
        lecture_id: lecture.id, title: "Mo 10", capacity: 8,
      });
      const item = await factory.create("registration_item", [], {
        registration_campaign_id: campaign.id,
        registerable_type: "Tutorial", registerable_id: tutorial.id,
      });
      const registrant = await factory.create("confirmed_user", [], {
        name_in_tutorials: "Alan Turing",
      });
      await factory.create("registration_user_registration", ["confirmed"], {
        registration_campaign_id: campaign.id, registration_item_id: item.id,
        user_id: registrant.id,
      });
      await campaign.__call("open!");

      await page.goto(`/lectures/${lecture.id}/edit`);
      await page.getByRole("tab", { name: "Participants" }).click();
      await page.getByPlaceholder("Search by name or matriculation number").fill("Turing");
      await expect(page.getByText("There is 1 match under “Registered”.")).toBeVisible();

      await page.getByRole("link", { name: /^Registered/ }).click();

      const row = page.getByRole("row").filter({ hasText: "Alan Turing" });
      await expect(row).toContainText("Mo 10");
      await expect(row).toContainText("Confirmed");
    });
});
