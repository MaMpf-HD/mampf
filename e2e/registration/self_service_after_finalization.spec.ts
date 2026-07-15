import { enableFeature } from "../_support/backend";
import { expect, test, Page } from "../_support/fixtures";
import { FactoryBot, FactoryBotObject } from "../_support/factorybot";

/**
 * Finalizing a campaign leaves every group with self-enrollment disabled, so
 * students end up silently locked into their allocation. The modal makes the
 * teacher decide.
 */
test.describe("self-enrollment prompt after finalization", () => {
  test.beforeEach(async ({ request }) => {
    await enableFeature(request, "roster_maintenance");
    await enableFeature(request, "registration_campaigns");
  });

  async function finalizeCampaign(
    page: Page, factory: FactoryBot, teacherId: number,
  ): Promise<FactoryBotObject> {
    const lecture = await factory.create("lecture", [], { teacher_id: teacherId });
    const campaign = await factory.create(
      "registration_campaign", ["closed", "first_come_first_served"],
      { campaignable_type: "Lecture", campaignable_id: lecture.id, items_count: 2 },
    );

    // the groups the campaign just filled are locked in — the state the modal exists for
    expect(await campaign.__call("shared_self_materialization_mode")).toBe("disabled");

    page.on("dialog", dialog => dialog.accept()); // finalizing asks for confirmation

    await page.goto(`/lectures/${lecture.id}/edit?tab=groups`);
    await page.getByRole("button", { name: "Finalize Allocation" }).click();

    return campaign;
  }

  test("applies the chosen mode to the campaign's groups",
    async ({ factory, teacher: { page, user } }) => {
      const campaign = await finalizeCampaign(page, factory, user.id);

      const modal = page.getByTestId("self-service-modal");
      await expect(modal).toBeVisible();

      // the recommended option is preselected (instead of the current state being preselected)
      await expect(modal.getByTestId("self-service-mode")).toHaveValue("add_and_remove");

      await modal.getByRole("button", { name: "Apply" }).click();
      await expect(modal).toBeHidden();

      expect(await campaign.__call("shared_self_materialization_mode"))
        .toBe("add_and_remove");
    });

  test("leaves the groups locked when the teacher declines",
    async ({ factory, teacher: { page, user } }) => {
      const campaign = await finalizeCampaign(page, factory, user.id);

      const modal = page.getByTestId("self-service-modal");
      await expect(modal).toBeVisible();

      await modal.getByRole("button", { name: "Keep self-enrollment disabled" }).click();
      await expect(modal).toBeHidden();

      expect(await campaign.__call("shared_self_materialization_mode")).toBe("disabled");
    });
});
