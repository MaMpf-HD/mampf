import { expect, test } from "./_support/fixtures";

// The groups tab keeps `registration_section=campaign` in the URL once that
// section has been chosen. As soon as a campaign exists, that combination
// collapses the section holding the group tiles, so the tutorials look gone.
test("keeps the group tiles visible once a campaign exists",
  async ({ factory, teacher: { page, user } }) => {
    const lecture = await factory.create("lecture", [], {
      teacher_id: user.id, locale: "en",
    });
    await factory.create("tutorial", [], { lecture_id: lecture.id, title: "Mo 10" });
    await factory.create("registration_campaign", [], {
      campaignable_id: lecture.id, campaignable_type: "Lecture",
    });

    await page.goto(`/lectures/${lecture.id}/edit?tab=groups&registration_section=campaign`);
    await expect(page.getByTestId("registration-no-campaign-section")).toBeVisible();

    await expect(page.getByText("Mo 10")).toBeVisible();
  });
