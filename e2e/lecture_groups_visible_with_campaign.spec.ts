import { expect, test } from "./_support/fixtures";

// The tab keeps `registration_section=campaign` in the URL once that section
// has been chosen, which is why the test carries it. The group tiles stay
// visible beside it; only a section with nothing left outside the campaigns
// folds away.
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
